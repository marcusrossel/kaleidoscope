//
//  Token.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

/// The `Token` type used by `Lexer`.
enum Token: Equatable {
  case variableKeyword
  case functionKeyword
  case externalKeyword

  case identifier(String)
  case numberLiteral(Double)

  case other(Character)

  static func ==(lhs: Token, rhs: Token) -> Bool {
    switch (lhs, rhs) {
    case (.variableKeyword, .variableKeyword):       return true
    case (.functionKeyword, .functionKeyword):       return true
    case (.externalKeyword, .externalKeyword):       return true
    case let (.identifier(l), .identifier(r)):       return l == r
    case let (.numberLiteral(l), .numberLiteral(r)): return l == r
    case let (.other(l), .other(r)):                 return l == r
    default:                                         return false
    }
  }
}

// Helper method.
internal extension Character {
  func isPart(of set: CharacterSet) -> Bool {
    return String(self).rangeOfCharacter(from: set) != nil
  }
}

/// A namespace that contains all of the `tokenTransforms` used by `Lexer`.
enum TokenTransform {
  /// Detects and ignores whitespaces, single-, and multi-line comments.
  ///
  /// Single-line comments begin with `//` and end with a new-line character.
  /// Multi-line comments begin with `/*` and end with `*/`.
  ///
  /// - Returns: `nil`
  @discardableResult
  static func forSkippables(_ buffer: inout Character, _ lexer: Lexer)
  -> Token? {
    var matchedSkippable: Bool

    repeat {
      matchedSkippable = false

      // Identifies and ignores whitespaces.
      if buffer.isPart(of: .whitespaces) {
        matchedSkippable = true
        buffer = lexer.nextCharacter()
      }

      // Identifies and ignores comments.
      if buffer == "/" {
        var matchedComment = false

        // Handles single-line comments.
        if lexer.nextCharacter(peek: true) == "/" {
          matchedComment = true

          // Could be omitted.
          buffer = lexer.nextCharacter()

          while !lexer.nextCharacter(peek: true).isPart(of: .newlines) {
            buffer = lexer.nextCharacter()
            if buffer == lexer.endOfFile { break }
          }
        }

        // Handles multi-line comments.
        if lexer.nextCharacter(peek: true) == "*" {
          matchedComment = true

          // Could be omitted.
          buffer = lexer.nextCharacter()

          // By adding a padding to the front of `commentBuffer' and removing
          // the first character on each iteration, the `contains` method stays
          // at O(2) instead of O(n).
          var commentBuffer = " \(lexer.nextCharacter())"

          repeat {
            buffer = lexer.nextCharacter()
            if buffer == lexer.endOfFile {
              fatalError("Multi-line comment was not closed.")
            }

            commentBuffer.append(buffer)
            commentBuffer.remove(at: commentBuffer.startIndex)
          } while !commentBuffer.contains("*/")
        }

        if matchedComment {
          // Set the buffer to the first character after a comment.
          buffer = lexer.nextCharacter()
          matchedSkippable = true
        }
      }
    } while matchedSkippable

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
  static func forNumbers(_ buffer: inout Character, _ lexer: Lexer) -> Token? {
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
          numberBuffer.characters.last != "_" &&
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
  // Valid keywords are:
  // * `var`
  // * `func`
  // * `extern`
  static func forIdentifiers(_ buffer: inout Character, _ lexer: Lexer)
  -> Token? {
    guard buffer.isPart(of: .letters) || buffer == "_" else { return nil }
    var identifierBuffer = ""

    repeat {
      identifierBuffer.append(buffer)
      buffer = lexer.nextCharacter()
    } while buffer.isPart(of: .alphanumerics) || buffer == "_"

    // Returns an `.identifier` or `.*Keyword` dependent on `identifierBuffer`.
    switch identifierBuffer {
    case "var": return .variableKeyword
    case "func": return .functionKeyword
    case "extern": return .externalKeyword
    default: return .identifier(identifierBuffer)
    }
  }
}
