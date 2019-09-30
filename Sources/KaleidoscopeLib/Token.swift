//
//  Token.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

public enum Token {
    
    case keyword(Keyword)
    case identifier(String)
    case number(Double)
    
    case `operator`(Operator)
    case symbol(Symbol)
    
    public enum Keyword: String {
        case `if`
        case then
        case `else`
        case definition = "def"
        case external = "extern"
    }
    
    public enum Symbol: Character {
        case leftParenthesis = "("
        case rightParenthesis = ")"
        case comma = ","
        case semicolon = ";"
    }
}

public enum Operator: Character {
    case plus = "+"
    case minus = "-"
    case times = "*"
    case divide = "/"
    case modulo = "%"
}

extension Token: Equatable { }
extension Token.Keyword: Equatable { }
extension Token.Symbol: Equatable { }
extension Operator: Equatable { }

