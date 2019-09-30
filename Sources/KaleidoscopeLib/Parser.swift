//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 08.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

public protocol TokenStream {
    
    associatedtype Token
    
    func nextToken() throws -> Token?
}


public final class Parser<Tokens: TokenStream> where Tokens.Token == Token {
    
    public enum Error: Swift.Error {
        case unexpectedToken(Token?)
    }
    
    public init(tokens: Tokens) throws {
        self.tokens = tokens
        try consumeToken()
    }
    
    private var tokens: Tokens
    // This value being `nil` is equivalent to an EOF.
    private var currentToken: Token?
    
    private func consumeToken() throws {
        currentToken = try tokens.nextToken()
    }
    
    private func consumeToken(_ target: Token) throws {
        if currentToken != target {
            throw Error.unexpectedToken(currentToken)
        } else {
            try consumeToken()
        }
    }
    
    public func parseFile() throws -> AST {
        var ast = AST()
        
        while currentToken != nil {
            switch currentToken {
            case .keyword(.external)?:
                ast.externals.append(try parseExternalFunction())
            case .keyword(.definition)?:
                ast.functions.append(try parseFunction())
            default:
                ast.expressions.append(try parseExpression())
            }
        }
        
        return ast
    }
}

// Primitives
extension Parser {
    
    private func parseTuple<Element>(parsingFunction: () throws -> Element) throws -> [Element] {
        try consumeToken(.symbol(.leftParenthesis))
        var elements: [Element] = []
        
        while currentToken != Token.symbol(.rightParenthesis) {
            let element = try parsingFunction()
            elements.append(element)
            _ = try? consumeToken(.symbol(.comma))
        }
        
        try consumeToken() // .symbol(.rightParenthesis)
        return elements
    }
    
    private func parseIdentifier() throws -> String {
        guard case let Token.identifier(identifier)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        try consumeToken() // .identifier
        
        return identifier
    }
}

// Functions
extension Parser {
    
    private func parsePrototype() throws -> Prototype {
        let identifier = try parseIdentifier()
        let parameters = try parseTuple(parsingFunction: parseIdentifier)
        
        return Prototype(name: identifier, parameters: parameters)
    }
    
    private func parseExternalFunction() throws -> Prototype {
        try consumeToken(.keyword(.external))
        let prototype = try parsePrototype()
        try consumeToken(.symbol(.semicolon))
        
        return prototype
    }
    
    private func parseFunction() throws -> Function {
        try consumeToken(.keyword(.definition))
        let prototype = try parsePrototype()
        let expression = try parseExpression()
        try consumeToken(.symbol(.semicolon))
        
        return Function(head: prototype, body: expression)
    }
}

// Expressions
extension Parser {
    
    private func parseExpression() throws -> Expression {
        var expression: Expression
        
        switch currentToken {
        case .symbol(.leftParenthesis)?:
            expression = try parseParenthesizedExpression()
        case .number?:
            expression = try parseNumberExpression()
        case .identifier(let identifier)?:
            expression = (try? parseCallExpression()) ?? .variable(identifier)
        case .keyword(.if)?:
            expression = try parseIfExpression()
        default:
            throw Error.unexpectedToken(currentToken)
        }
        
        if let binaryExpression = try? parseBinaryExpressionFromOperator(lhs: expression) {
            expression = binaryExpression
        }
        
        return expression
    }
    
    private func parseParenthesizedExpression() throws -> Expression {
        try consumeToken(.symbol(.leftParenthesis))
        let enclosedExpression = try parseExpression()
        try consumeToken(.symbol(.rightParenthesis))
        
        return enclosedExpression
    }
    
    private func parseCallExpression() throws -> Expression {
        let identifier = try parseIdentifier()
        let arguments = try parseTuple(parsingFunction: parseExpression)
        
        return .call(identifier, arguments: arguments)
    }
    
    private func parseIfExpression() throws -> Expression {
        try consumeToken(.keyword(.if))
        let condition = try parseExpression()
        try consumeToken(.keyword(.then))
        let then = try parseExpression()
        try consumeToken(.keyword(.else))
        let `else` = try parseExpression()
        
        return .if(condition: condition, then: then, else: `else`)
    }
    
    private func parseNumberExpression() throws -> Expression {
        guard case let Token.number(number)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        try consumeToken() // .numberLiteral
        
        return .number(number)
    }
    
    private func parseBinaryExpressionFromOperator(lhs: Expression) throws -> Expression {
        guard case let Token.operator(`operator`)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        try consumeToken() // .operator
        
        let rhs = try parseExpression()
        
        return .binary(lhs: lhs, operator: `operator`, rhs: rhs)
    }
}
