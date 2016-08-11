//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 06.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

extension Character {
  func belongs(to characterSet: CharacterSet) -> Bool {
    return String(self).rangeOfCharacter(from: characterSet) != nil
  }
}

class Lexer {
  typealias Tokenizer = (buffer: inout Character) -> Token?
  static var EndOfPlainText: Character = "\0"

  static var plainText = ""

  static var tokenizers: [Tokenizer] = [
    Lexer.lexSkippable,
    Lexer.lexIdentifier,
    Lexer.lexIntegerLiteral,
  ]
  static var afterTokenization: (buffer: Character) -> () = { buffer in
    plainText.insert(buffer, at: plainText.startIndex)
  }

  /// Returns the `EndOfPlainText` character if `plainText` is fully
  /// consumed.
  static func consumeCharacter() -> Character {
    guard !plainText.isEmpty else { return EndOfPlainText }
    return plainText.remove(at: plainText.startIndex)
  }

  /// Allows checking the next character without consuming it.
  static func peekCharacter() -> Character {
    guard !plainText.isEmpty else { return EndOfPlainText }
    return plainText[plainText.startIndex]
  }

  /// - Important: Returns `Token.other("\0")` when `plainText` is fully lexed.
  static func nextToken() -> Token {
    defer { afterTokenization(buffer: buffer) }

    var buffer: Character = consumeCharacter()

    for tokenizer in tokenizers {
      if let token = tokenizer(buffer: &buffer) { return token }
    }

    defer { buffer = consumeCharacter() }
    return Token.other(buffer)
  }
}

extension Lexer {
  @discardableResult
  static func lexSkippable(buffer: inout Character) -> Token? {
    var matchedSkippable: Bool

    repeat {
      matchedSkippable = false

      // Identifies and ignores whitespaces.
      if buffer.belongs(to: .whitespaces) {
        matchedSkippable = true
        buffer = consumeCharacter()
      }

      // Identifies and ignores comments.
      if buffer == "/" {
        var matchedComment = false

        // Handles single-line comments.
        if peekCharacter() == "/" {
          matchedComment = true

          // Could be omitted.
          buffer = consumeCharacter()

          while !peekCharacter().belongs(to: .newlines) {
            buffer = consumeCharacter()
            if buffer == EndOfPlainText { break }
          }
        }

        // Handles multi-line comments.
        if peekCharacter() == "*" {
          matchedComment = true

          // Could be omitted.
          buffer = consumeCharacter()

          // By adding a padding to the front of `commentBuffer' and removing the
          // first character on each iteration, the `contains` method stays at
          // O(2) instead of O(n).
          var commentBuffer = " \(consumeCharacter())"

          repeat {
            buffer = consumeCharacter()
            if buffer == EndOfPlainText {
              fatalError("Multi-line comment was not closed.")
            }

            commentBuffer.append(buffer)
            commentBuffer.remove(at: commentBuffer.startIndex)
          } while !commentBuffer.contains("*/")
        }

        if matchedComment {
          // Set the buffer to the first character after a comment.
          buffer = consumeCharacter()
          matchedSkippable = true
        }
      }
    } while matchedSkippable

    return nil
  }

  static func lexIdentifier(buffer: inout Character) -> Token? {
    guard buffer.belongs(to: .letters) else { return nil }
    var identifierBuffer = ""

    repeat {
      identifierBuffer.append(buffer)
      buffer = consumeCharacter()
    } while buffer.belongs(to: .alphanumerics)

    // Returns an `.identifier` or `.keyword` dependent on `identifierBuffer`.
    return Token.forIdentifier(identifierBuffer)
  }

  static func lexIntegerLiteral(buffer: inout Character) -> Token? {
    guard buffer.belongs(to: .decimalDigits) else { return nil }
    var numberBuffer = ""

    repeat {
      numberBuffer.append(buffer)
      buffer = consumeCharacter()
    } while buffer.belongs(to: .decimalDigits) || buffer == "_"

    guard let integer = Int(numberBuffer) else {
      fatalError("Lexer Error: Was not able to convert `String` \"\(numberBuffer)\" to `Int`.")
    }

    return .integerLiteral(integer)
  }

  /*static func lexNumbers(buffer: inout Character) -> Token? {
    guard buffer.belongs(to: .decimalDigits) || buffer == "." else { return nil }
    var numberBuffer = ""

    repeat {
      numberBuffer.append(buffer)
      buffer = consumeCharacter()
    } while buffer.belongs(to: .decimalDigits) ||
      (buffer == "." && !numberBuffer.contains("."))

    guard let number = Double(numberBuffer) else {
      fatalError("Was not able to convert `String` \"\(numberBuffer)\" to `Double`.")
    }

    return Token.number(number)
  }*/
}

