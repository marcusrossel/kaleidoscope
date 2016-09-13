//
//  Token.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 11.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

struct Keyword {
  static let variable = "var"
  static let function = "func"
  static let external = "extern"

  static var allKeywords: [String] {
    return [
      variable,
      function,
      external,
    ]
  }
}

enum Token {
  case keyword(String)
  case identifier(String)
  case integerLiteral(Int)

  case other(Character)

  static func forIdentifier(_ identifier: String) -> Token {
    if Keyword.allKeywords.contains(identifier) {
      return .keyword(identifier)
    } else {
      return .identifier(identifier)
    }
  }
}
