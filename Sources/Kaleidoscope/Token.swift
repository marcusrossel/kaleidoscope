//
//  Token.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import LexerProtocol

/// The token-type used by the lexer.
enum Token: Equatable {
    
    case keyword(Keyword)
    case identifier(String)
    case numberLiteral(Double)
    
    case `operator`(Operator)
    case symbol(Symbol)
    
    case other(Character)
    
    enum Keyword: String, Equatable {
        case `if`
        case then
        case `else`
        case function = "func"
        case external = "extern"
    }
    
    enum Symbol: Character, Equatable {
        case endOfFile = "\0"
        case newLine = "\n"
        case leftParenthesis = "("
        case rightParenthesis = ")"
        case comma = ","
        case semicolon = ";"
    }
}

enum Operator: Character, Equatable {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case divide = "/"
    case modulo = "%"
    case equals = "="
}
