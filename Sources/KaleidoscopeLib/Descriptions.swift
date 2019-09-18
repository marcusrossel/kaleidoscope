//
//  Descriptions.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 12.09.19.
//

extension Token.Keyword: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return rawValue
    }
}

extension Token.Symbol: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .endOfFile: return "EOF"
        case .newLine: return "newLine"
        default: return "\"\(rawValue)\""
        }
    }
}

extension Operator: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "\(rawValue)"
    }
}

extension AST: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var description = "AST<"
        
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
    
    public var debugDescription: String {
        return "Prototype<\(name)(\(parameters.joined(separator: ", ")))>"
    }
}

extension Function: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "Function<\(head) |body: \(body)>"
    }
}

extension Expression: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .number(let value):
            return "\(value)"
        case .variable(let name):
            return "$\(name)"
        case let .binary(lhs: lhs, operator: `operator`, rhs: rhs):
            return "\(lhs) \(`operator`) \(rhs)"
        case let .call(function, arguments):
            let argumentList = arguments.map { $0.debugDescription }.joined(separator: ", ")
            return "Call<\(function)(\(argumentList))>"
        case let .if(condition: condition, then: then, else: `else`):
            return "If<\(condition) |then: \(then) |else: \(`else`)>"
        }
    }
}
