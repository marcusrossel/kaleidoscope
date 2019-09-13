//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 08.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

/* Target grammar:
 
<function>  ::= "func" <prototype> <expr> ";"
<extern>    ::= "extern" <prototype> ";"
<prototype> ::= <identifier> "(" <params> ")"
<params>    ::= <identifier> | <identifier> "," <params>
<expr>      ::= <binary> | <call> | <identifier> | <number> | <ifelse> | "(" <expr> ")"
<call>      ::= <identifier> "(" <arguments> ")"
<arguments> ::= <expr> | <expr> "," <arguments>
<ifelse>    ::= "if" <expr> "then" <expr> "else" <expr>
<binary>    ::= <expr> <operator> <expr>
<operator>  ::= "+" | "-" | "*" | "/" | "%"
 
*/

public final class Parser<Tokens: IteratorProtocol> where Tokens.Element == Token {
    
    public enum Error: Swift.Error {
        case unexpectedToken(Token?)
    }
    
    public init(tokens: Tokens) {
        self.tokens = tokens
        consumeToken()
    }
    
    private var tokens: Tokens
    // This value being `nil` is equivalent to an EOF.
    private var currentToken: Token?
    
    private func consumeToken(ignoringNewLines: Bool = true) {
        repeat { currentToken = tokens.next() }
        while ignoringNewLines && currentToken == .symbol(.newLine)
    }
    
    private func consumeToken(_ target: Token, ignoringNewLines: Bool = true) throws {
        if ignoringNewLines && currentToken == .symbol(.newLine) { consumeToken() }
        
        if currentToken != target {
            throw Error.unexpectedToken(currentToken)
        } else {
            consumeToken()
        }
    }
    
    public func parseFile() throws -> File {
        var file = File()
        
        while currentToken != nil {
            switch currentToken {
            case .keyword(.external)?:
                file.externals.append(try parseExternalFunction())
            case .keyword(.function)?:
                file.functions.append(try parseFunction())
            default:
                file.expressions.append(try parseExpression())
            }
        }
        
        return file
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
        
        consumeToken() // .symbol(.rightParenthesis)
        return elements
    }
    
    private func parseIdentifier() throws -> String {
        guard case let Token.identifier(identifier)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        consumeToken() // .identifier
        
        return identifier
    }
}

// Functions
extension Parser {
    
    private func parsePrototype() throws -> Prototype {
        let identifier = try parseIdentifier()
        let parameters = try parseTuple(parsingFunction: parseIdentifier)
        
        return Prototype(name: identifier, arguments: parameters)
    }
    
    private func parseExternalFunction() throws -> Prototype {
        try consumeToken(.keyword(.external))
        let prototype = try parsePrototype()
        try consumeToken(.symbol(.semicolon))
        
        return prototype
    }
    
    private func parseFunction() throws -> Function {
        try consumeToken(.keyword(.function))
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
        case .numberLiteral?:
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
        guard case let Token.numberLiteral(number)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        consumeToken() // .numberLiteral
        
        return .number(number)
    }
    
    private func parseBinaryExpressionFromOperator(lhs: Expression) throws -> Expression {
        guard case let Token.operator(`operator`)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        consumeToken() // .operator
        
        let rhs = try parseExpression()
        
        return .binary(lhs: lhs, operator: `operator`, rhs: rhs)
    }
}
