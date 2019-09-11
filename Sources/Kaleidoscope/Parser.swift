//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 08.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

/* Target grammar:
 
 <prototype>  ::= <identifier> "(" <params> ")"
 <params>     ::= <identifier> | <identifier>, <params>
 <definition> ::= "def" <prototype> <expr> ";"
 <extern>     ::= "extern" <prototype> ";"
 <operator>   ::= "+" | "-" | "*" | "/" | "%"
 <expr>       ::= <binary> | <call> | <identifier> | <number> | <ifelse> | "(" <expr> ")"
 <binary>     ::= <expr> <operator> <expr>
 <call>       ::= <identifier> "(" <arguments> ")"
 <ifelse>     ::= "if" <expr> "then" <expr> "else" <expr>
 <arguments>  ::= <expr> | <expr> "," <arguments>
 
*/

final class Parser<Tokens: IteratorProtocol> where Tokens.Element == Token {
    
    enum Error: Swift.Error {
        case unexpectedToken(Token?)
    }
    
    init(tokens: Tokens) {
        self.tokens = tokens
        currentToken = self.tokens.next()
    }
    
    var tokens: Tokens
    // This value being `nil` is equivalent to an EOF.
    private var currentToken: Token?
    
    private func consumeToken() {
        currentToken = tokens.next()
    }
    
    private func consumeToken(_ target: Token) throws {
        if currentToken != target {
            throw Error.unexpectedToken(currentToken)
        } else {
            consumeToken()
        }
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
    
    func parsePrototype() throws -> Prototype {
        let identifier = try parseIdentifier()
        let parameters = try parseTuple(parsingFunction: parseIdentifier)
        
        return Prototype(name: identifier, arguments: parameters)
    }
    
    func parseExternalFunction() throws -> Prototype {
        try consumeToken(.keyword(.external))
        let prototype = try parsePrototype()
        try consumeToken(.symbol(.semicolon))
        
        return prototype
    }
    
    func parseFunction() throws -> Function {
        try consumeToken(.keyword(.function))
        let prototype = try parsePrototype()
        let expression = try parseExpression()
        try consumeToken(.symbol(.semicolon))
        
        return Function(head: prototype, body: expression)
    }
}

// Expressions
extension Parser {
    
    func parseExpression() throws -> Expression {
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
    
    func parseParenthesizedExpression() throws -> Expression {
        try consumeToken(.symbol(.leftParenthesis))
        let enclosedExpression = try parseExpression()
        try consumeToken(.symbol(.rightParenthesis))
        
        return enclosedExpression
    }
    
    func parseCallExpression() throws -> Expression {
        let identifier = try parseIdentifier()
        let arguments = try parseTuple(parsingFunction: parseExpression)
        
        return .call(identifier, arguments: arguments)
    }
    
    func parseIfExpression() throws -> Expression {
        try consumeToken(.keyword(.if))
        let condition = try parseExpression()
        try consumeToken(.keyword(.then))
        let then = try parseExpression()
        try consumeToken(.keyword(.else))
        let `else` = try parseExpression()
        
        return .if(condition: condition, then: then, else: `else`)
    }
    
    func parseNumberExpression() throws -> Expression {
        guard case let Token.numberLiteral(number)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        consumeToken() // .numberLiteral
        
        return .number(number)
    }
    
    func parseBinaryExpressionFromOperator(lhs: Expression) throws -> Expression {
        guard case let Token.operator(`operator`)? = currentToken else {
            throw Error.unexpectedToken(currentToken)
        }
        consumeToken() // .operator
        
        let rhs = try parseExpression()
        
        return .binary(lhs: lhs, operator: `operator`, rhs: rhs)
    }
}
