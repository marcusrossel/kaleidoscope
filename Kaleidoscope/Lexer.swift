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

public class Lexer {
  private static var EndOfPlainText: Character = "\0"

  public enum Token {
    // Keywords.
    case variable
    case function
    case external

    case identifier(String)
    case number(Double)

    // Tokens determined by the parser.
    case other(Character)
  }

  public static var plainText = "" { didSet { consumingPlainText = plainText } }
  private static var consumingPlainText = ""

  /// Returns the `EndOfPlainText` character if `consumingPlainText` is fully
  /// consumed.
  private static func consumeCharacter() -> Character {
    guard !consumingPlainText.isEmpty else { return EndOfPlainText }
    return consumingPlainText.remove(at: consumingPlainText.startIndex)
  }

  /// Allows checking the next character without consuming it.
  private static func peekCharacter() -> Character {
    guard !consumingPlainText.isEmpty else { return EndOfPlainText }
    return consumingPlainText[consumingPlainText.startIndex]
  }

  /// - Important: Returns `Token.other("\0")` when `plainText` is fully lexed.
  public static func nextToken() -> Token {
    defer {
      consumingPlainText.insert(buffer, at: consumingPlainText.startIndex)
    }

    var buffer: Character = consumeCharacter()

    lexSkippables(buffer: &buffer)

    if buffer.belongs(to: .letters) {
      return lexIdentifiersAndKeywords(buffer: &buffer)
    }

    // Identifies numbers.
    if buffer.belongs(to: .decimalDigits) || buffer == "." {
      return lexNumbers(buffer: &buffer)
    }

    defer { buffer = consumeCharacter() }
    return Token.other(buffer)
  }

  private static func lexSkippables(buffer: inout Character) {
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
  }

  private static func lexIdentifiersAndKeywords(buffer: inout Character) -> Token {
    var identifierBuffer = ""

    repeat {
      identifierBuffer.append(buffer)
      buffer = consumeCharacter()
    } while buffer.belongs(to: .alphanumerics)

    // Returns a keyword token or an identifier token with the associated
    // string.
    switch identifierBuffer {
    case "var": return Token.variable
    case "func": return Token.function
    case "extern": return Token.external
    default: return Token.identifier(identifierBuffer)
    }
  }

  private static func lexNumbers(buffer: inout Character) -> Token {
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
  }
}

