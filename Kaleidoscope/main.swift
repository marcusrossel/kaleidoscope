//
//  main.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 08.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

let plainText =
  "// A function that takes two parameters" + "\n" +
    "func(param1, param2) {"                  + "\n" +
    "  var a = 3.141592"                      + "\n" +
    "  var b = .718121828"                    + "\n" +
    "  /* `a` and `b` could"                  + "\n" +
    "  be constants */"                       + "\n" +
    "  extern(a + b)"                         + "\n"

Lexer.plainText = plainText

var tokenBuffer: Lexer.Token
while true {
  tokenBuffer = Lexer.nextToken()
  if case Lexer.Token.other(let character) = tokenBuffer where character == "\0" { break }
  print(tokenBuffer)
}
