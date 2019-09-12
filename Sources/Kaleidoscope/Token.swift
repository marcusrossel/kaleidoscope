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
    
    enum Keyword: String, Equatable, CustomDebugStringConvertible {
        case `if`
        case then
        case `else`
        case function = "func"
        case external = "extern"
        
        var debugDescription: String {
            return rawValue
        }
    }
    
    enum Symbol: Character, Equatable, CustomDebugStringConvertible {
        case endOfFile = "\0"
        case newLine = "\n"
        case leftParenthesis = "("
        case rightParenthesis = ")"
        case comma = ","
        case semicolon = ";"
        
        var debugDescription: String {
            switch self {
            case .endOfFile: return "EOF"
            case .newLine: return "newLine"
            default: return "\"\(rawValue)\""
            }
        }
    }
}

enum Operator: Character, Equatable, CustomDebugStringConvertible {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case divide = "/"
    case modulo = "%"
    case equals = "="
    
    var debugDescription: String {
        return "\"\(rawValue)\""
    }
}
