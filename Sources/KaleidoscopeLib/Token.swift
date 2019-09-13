//
//  Token.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import LexerProtocol

/// The token-type used by the lexer.
public enum Token: Equatable {
    
    case keyword(Keyword)
    case identifier(String)
    case numberLiteral(Double)
    
    case `operator`(Operator)
    case symbol(Symbol)
    
    case other(Character)
    
    public enum Keyword: String, Equatable {
        case `if`
        case then
        case `else`
        case function = "func"
        case external = "extern"
    }
    
    public enum Symbol: Character, Equatable {
        case endOfFile = "\0"
        case newLine = "\n"
        case leftParenthesis = "("
        case rightParenthesis = ")"
        case comma = ","
        case semicolon = ";"
    }
}

public enum Operator: Character, Equatable {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case divide = "/"
    case modulo = "%"
    case equals = "="
}
