//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

final class Lexer: LexerProtocol {
  var text = ""
  var position = 0
  var endOfFile: Character = "\0"

  var defaultTransform: (inout Character, Lexer) -> Token = { buffer, _ in
    .other(buffer)
  }

  var tokenTransforms = [
    TokenTransform.forSkippables,
    TokenTransform.forIdentifiers,
    TokenTransform.forNumbers
  ]
}
