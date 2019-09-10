//
//  LexerProtocol.swift
//  Lexer Protocol
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

public protocol LexerProtocol: class {
  /// The type used as the token-type by the lexer-class.
  associatedtype Token

  /// A token-transform that is guaranteed to produce a token.
  typealias GuaranteedTransform = (
    _ buffer: inout Character,
    _ lexer: Self
  ) -> Token

  /// A token-transform that might produce a token or could fail.
  typealias PossibleTransform = (
    _ buffer: inout Character,
    _ lexer: Self
  ) -> Token?

  /// The plain text, which will be lexed.
  var text: String { get set }

  /// Used to keep track of the current relevant character in `text`.
  var position: Int { get set }

  /// The character that signifies that the end of `text` is reached.
  ///
  /// - Note: This character is used to circumvent the need to return an
  /// optional from `nextCharacter()`.
  var endOfFile: Character { get set }

  /// A default guaranteed token-generating transform which is called when all
  /// other `tokenTransforms` fail.
  var defaultTransform: GuaranteedTransform { get set }

  /// A sequence of token-generating transforms, which will be called in order
  /// in `nextToken()`.
  ///
  /// - Note: These transforms are inteded to perform the pattern matching,
  /// aswell. If it fails `nil` can therefore be returned.
  var tokenTransforms: [PossibleTransform] { get set }
}

public extension LexerProtocol {
  /// Returns the the next character in `text`.
  ///
  /// - Note: If `position` has reached `text`'s maximum index, it's considered
  /// consumed and `endOfFile` is returned.
  ///
  /// - Parameter peek: Determines whether or not the character that's being
  /// returned is consumed or not.
  /// - Parameter stride: The offset from the current `position` that the
  /// character to be returned is at. When `peek` is `false` this consumes all
  /// of the characters in range of the `offset`.
  func nextCharacter(peek: Bool = false, stride: Int = 1) -> Character {
    guard stride >= 1 else {
      fatalError("Lexer Error: \(#function): `stride` must be >= 1.\n")
    }

    let nextCharacterIndex = position + stride - 1

    defer {
      if !peek && nextCharacterIndex <= text.count {
        position += stride
      }
    }
    guard nextCharacterIndex < text.count else { return endOfFile }

    return text[text.index(text.startIndex, offsetBy: position + stride - 1)]
  }

  /// Returns the next `Token` according to the following system:
  ///
  /// 1. Stores next character in a buffer.
  /// 2. Sequentially calls the `tokenTransforms`.
  /// 3. If one of the `tokenTransforms` succeeds it's `Token` is returned, and
  /// the remaining buffer character is restored.
  /// 4. If all `tokenTransforms` return `nil` the `defaultTransform`'s return
  /// value is returned.
  func nextToken() -> Token {
    var buffer = nextCharacter()

    for transform in tokenTransforms {
      if let token = transform(&buffer, self) {
        defer { position -= 1 }
        return token
      }
    }

    return defaultTransform(&buffer, self)
  }
}
