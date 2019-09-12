//
//  AST.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 09.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

struct File {
    var functions: [Function] = []
    var externals: [Prototype] = []
    var expressions: [Expression] = []
}

struct Prototype {
    var name: String
    var arguments: [String]
}

struct Function {
    var head: Prototype
    var body: Expression
}

indirect enum Expression {
    case number(Double)
    case variable(String)
    case binary(lhs: Expression, operator: Operator, rhs: Expression)
    case call(String, arguments: [Expression])
    case `if`(condition: Expression, then: Expression, else: Expression)
}

// Printing

extension File: CustomDebugStringConvertible {
    
    var debugDescription: String {
        var description = "File<"
        
        description += "\n  Functions:"
        for function in functions { description += "\n    \(function)" }
        
        description += "\n\n  External Functions:"
        for external in externals { description += "\n    \(external)" }
        
        description += "\n\n  Expressions:"
        for expression in expressions { description += "\n    \(expression)" }
        
        description += "\n>"
        
        return description
    }
}

extension Prototype: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Prototype<\(name)(\(arguments.joined(separator: ", ")))>"
    }
}

extension Function: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Function<\(head) | \(body)>"
    }
}

extension Expression: CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case .number(let value): return "\(value)"
        case .variable(let name): return "$\(name)"
        case let .binary(lhs: lhs, operator: `operator`, rhs: rhs):
            return "\(lhs) \(`operator`) \(rhs)"
        case let .call(function, arguments):
            let argumentList = arguments.map { $0.debugDescription }.joined(separator: ", ")
            return "Call<\(function)(\(argumentList))>"
        case let .if(condition: condition, then: then, else: `else`):
            return "(\(condition)) ? \(then) : \(`else`)"
        }
    }
}
