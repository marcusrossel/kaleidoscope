//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import LexerProtocol
import Foundation

final class Lexer: LexerProtocol {
    
    typealias Token = Kaleidoscope.Token

    init(text: String) {
        self.text = text
    }
    
    var text = ""
    var position = 0
    var endOfText: Character = "\0"
    
    var defaultTransform: (inout Character, Lexer) -> Token = { buffer, lexer in
        defer { buffer = lexer.nextCharacter() }
        return .other(buffer)
    }
    
    var tokenTransforms = [
        TokenTransform.forSkippables,
        TokenTransform.forIdentifiersAndKeywords,
        TokenTransform.forNumbers,
        TokenTransform.forSingleCharacterTokens,
    ]
    
    /// Customizes the iteration behaviour of the lexer to stop when the end-of-file token is
    /// encountered.
    func next() -> Token? {
        let token = nextToken()
        return (token == .symbol(.endOfFile)) ? nil : token
    }
}

/// A namespace that contains all of the token-transforms used by the lexer.
enum TokenTransform {

    /// Combines the whitespace and comment transforms, as they always return `nil` and can
    /// therefore not "restart the lexer's transform-pipeline".
    ///
    /// This method only works as long as this transform is the first.
    @discardableResult
    fileprivate static func forSkippables(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
        var initialPosition: Int
        
        repeat {
            initialPosition = lexer.position
            
            TokenTransform.forWhitespace(&buffer, lexer)
            TokenTransform.forComments(&buffer, lexer)
        } while lexer.position != initialPosition
        
        return nil
    }
    
    /// Detects and ignores whitespace.
    ///
    /// - Returns: `nil`
    @discardableResult
    fileprivate static func forWhitespace(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
        while buffer.isPart(of: .whitespaces) { buffer = lexer.nextCharacter() }
        return nil
    }
    
    /// Detects and ignores single- and multi-line comments.
    ///
    /// Single-line comments begin with `//` and end with a new-line character.
    /// Multi-line comments begin with `/*` and end with `*/`.
    ///
    /// - Returns: `nil`
    @discardableResult
    fileprivate static func forComments(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
        guard buffer == "/" else { return nil }
    
        // Handles single-line comments.
        if lexer.nextCharacter(peek: true) == "/" {
            let singleLineTerminators = CharacterSet.newlines.union(.init(charactersIn: "\0"))
            
            repeat { buffer = lexer.nextCharacter() }
            while !buffer.isPart(of: singleLineTerminators)
        }
        
        // Handles multi-line comments.
        if lexer.nextCharacter(peek: true) == "*" {
            buffer = lexer.nextCharacter() // buffer = "*"
            
            // By adding a padding to the front of `commentBuffer` and removing
            // the first character on each iteration, the string comparison stays at O(1) instead of
            // O(n). The array reallocation should also be O(1) each iteration, as array.count == 3
            // is invariant.
            var commentBuffer = "  " // two spaces
            
            repeat {
                buffer = lexer.nextCharacter()
                
                guard buffer != lexer.endOfText else {
                    print("Syntax Error: Multi-line comment was not closed.")
                    return nil
                }
                
                commentBuffer.append(buffer)
                commentBuffer.remove(at: commentBuffer.startIndex)
            } while commentBuffer != "*/"
            
            buffer = lexer.nextCharacter()
        }
        
        return nil
    }    
    
    /// Detects binary, octal, decimal and hexadecimal integer literals as well as
    /// floating-point literals.
    /// The different integer literal types are denoted by prefixes:
    /// * binary: `0b`
    /// * octal: `0o`
    /// * decimal: no prefix
    /// * hexadecimal: `0x`
    ///
    /// - Returns: An `.integer` token if an integer literal was detected, a
    /// `.floatingPoint` token if a floating-point token was detected, otherwise
    /// `nil`.
    fileprivate static func forNumbers(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
        // Determines if the number is negative, and if the first character after
        // the sign-character even qualifies for a number.
        let numberIsNegative = buffer == "-"
        let testBuffer = numberIsNegative ? lexer.nextCharacter(peek: true) : buffer
        
        guard testBuffer.isPart(of: .decimalDigits) else { return nil }
        if numberIsNegative { buffer = lexer.nextCharacter() }
        
        // An indicator used to eliminate the validity of a decimal point if an
        // integer-literal prefix (`0b`, `0o`, `0x`) has been used.
        var literalMustBeInteger = false
        
        // Assumes that the number literal will be a decimal integer.
        var validCharacters = "01234567890_"
        var radix = 10
        
        // Adjusts `validCharacters` and `radix` incase of binary, octal and
        // hexadecimal integer literals.
        nonDecimalIntegerRoutine: do {
            let peekBuffer = lexer.nextCharacter(peek: true)
            if buffer == "0" && peekBuffer.isPart(of: .letters) {
                switch peekBuffer {
                case "b": validCharacters = "01_"; radix = 2
                case "o": validCharacters = "01234567_"; radix = 8
                case "x": validCharacters = "0123456789abcdefABCDEF_"; radix = 16
                default: break nonDecimalIntegerRoutine
                }
                
                // Only if the first character after the prefix is valid, the integer
                // literal can be valid.
                let postPrefix = String(lexer.nextCharacter(peek: true, stride: 2))
                guard validCharacters.contains(postPrefix) else {
                    break nonDecimalIntegerRoutine
                }
                literalMustBeInteger = true
                buffer = lexer.nextCharacter(stride: 2)
            }
        }
        
        var numberBuffer = numberIsNegative ? "-" : ""
        
        // Condition closure that checks if a decimal point is valid given a certain
        // state.
        let isValidDecimalPoint = { (buffer: Character) -> Bool in
            guard buffer == "." else { return false }
            let nextCharacter = lexer.nextCharacter(peek: true)
            
            return
                !numberBuffer.contains(".") &&
                    numberBuffer.last != "_" &&
                    validCharacters.contains(String(nextCharacter)) &&
                    nextCharacter != "_"
        }
        
        // Gets all of the characters that belong to the literal and stores them in
        // `numberBuffer`.
        repeat {
            numberBuffer.append(buffer)
            buffer = lexer.nextCharacter()
        } while
            validCharacters.contains(String(buffer)) ||
            (!literalMustBeInteger && isValidDecimalPoint(buffer))
        
        // Removes the `_` characters, because otherwise the number-from-string
        // initializers fail.
        let trimmedBuffer = numberBuffer.replacingOccurrences(of: "_", with: "")
        
        let value: Double
        
        if trimmedBuffer.contains(".") {
            // Tries to convert the literal to a `Double`. If this fails, something is
            // wrong with the lexing process.
            guard let floatingPointValue = Double(trimmedBuffer) else {
                fatalError("Lexer Error: Was not able to convert `String`(" +
                    numberBuffer + ") to `Double`.\n")
            }
            value = floatingPointValue
        } else {
            // Tries to convert the literal to an `Int`. If this fails, something is
            // wrong with the lexing process.
            guard let integerValue = Int(trimmedBuffer, radix: radix) else {
                fatalError("Lexer Error: Was not able to convert `String`(" +
                    numberBuffer + ") to `Int`.\n")
            }
            value = Double(integerValue)
        }
        
        return .numberLiteral(value)
    }
    
    // Detects identifiers and keywords (specialized identifiers).
    //
    // An identifier must begin with a letter or a `_`. The body of the identifier
    // can contain either any alphanumeric character or `_`.
    //
    // Valid keywords are determined by `Token.Keyword`'s raw values.
    fileprivate static func forIdentifiersAndKeywords(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
        let validPrefix = CharacterSet.letters.union(.init(charactersIn: "_"))
        let validBody = CharacterSet.alphanumerics.union(.init(charactersIn: "_"))
        
        guard buffer.isPart(of: validPrefix) else { return nil }
        var identifierBuffer = ""
        
        repeat {
            identifierBuffer.append(buffer)
            buffer = lexer.nextCharacter()
        } while buffer.isPart(of: validBody)
        
        // Returns an `.identifier` or `.keyword` depending on the
        // identifier buffer.
        if let keyword = Token.Keyword(rawValue: identifierBuffer) {
            return .keyword(keyword)
        } else {
            return .identifier(identifierBuffer)
        }
    }
    
    static func forSingleCharacterTokens(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
        if let `operator` = Operator(rawValue: buffer) {
            buffer = lexer.nextCharacter()
            return .operator(`operator`)
        } else if let symbol = Token.Symbol(rawValue: buffer) {
            buffer = lexer.nextCharacter()
            return .symbol(symbol)
        } else {
            return nil
        }
    }
}

// Helper method.
extension Character {
    fileprivate func isPart(of set: CharacterSet) -> Bool {
        return String(self).rangeOfCharacter(from: set) != nil
    }
}
