//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 08.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

class Parser {
  private static func precedence(for token: Token) -> Int? {
    guard case let Token.other(`operator`) = token else { return nil }

    switch `operator` {
    case "<": return 10
    case "+": return 20
    case "-": return 20
    case "*": return 40
    default: return nil
    }
  }

  static var currentToken = Lexer.nextToken()

  static func parseIntegerLiteralExpression() -> ExpressionNode? {
    guard case let Token.integerLiteral(integer) = currentToken else {
      print("Parser Error: Called \(#function) on inappropriate token.")
      return nil
    }
    defer { currentToken = Lexer.nextToken() }
    return IntegerExpressionNode(value: integer)
  }

  static func parseParenthesesExpression() -> ExpressionNode? {
    guard case Token.other("(") = currentToken else {
      print("Parser Error: Called \(#function) on inappropriate token.")
      return nil
    }
    currentToken = Lexer.nextToken()

    guard let enclosedExpression = Parser.parseExpression() else { return nil }

    guard case Token.other(")") = currentToken else {
      print("Syntax Error: Expected `)`.")
      return nil
    }

    currentToken = Lexer.nextToken()
    return enclosedExpression
  }

  static func parseIdentifierExpression() -> ExpressionNode? {
    guard case let Token.identifier(identifier) = currentToken else {
      print("Parser Error: Called \(#function) on inappropriate token.")
      return nil
    }
    currentToken = Lexer.nextToken()

    guard case Token.other("(") = currentToken else {
      return VariableExpressionNode(name: identifier)
    }
    currentToken = Lexer.nextToken()

    var arguments = [ExpressionNode]()

    if case Token.other(")") = currentToken { } else {
      while true {
        guard let argument = parseExpression() else { return nil }
        arguments.append(argument)

        if case Token.other(")") = currentToken { break }

        if case Token.other(",") = currentToken { } else {
          print("Syntax Error: Expected `)` or `,` in argument list.")
          return nil
        }

        currentToken = Lexer.nextToken()
      }
    }

    currentToken = Lexer.nextToken()
    return CallExpressionNode(callee: identifier, arguments: arguments)
  }

  static func parsePrimaryExpression() -> ExpressionNode? {
    let parsingFunctions = [
      parseIntegerLiteralExpression,
      parseParenthesesExpression,
      parseIdentifierExpression
    ]

    for function in parsingFunctions {
      if let node = function() { return node }
    }

    print("Parser Error: Called \(#function) on inappropriate token.")
    return nil

    /* LLVM Method

     switch currentToken {
     case Lexer.Token.number: return parseNumberExpression()
     case Lexer.Token.other("("): return parseParenthesesExpression()
     case Lexer.Token.identifier: return parseIdentifierExpression()
     default:
     print("Parser Error: Called \(#function) on inappropriate token.")
     return nil
     }
     */
  }

  static func parseExpression() -> ExpressionNode? {
    guard var primaryExpression = parsePrimaryExpression() else { return nil }
    return parseBinaryOperation(minimalPrecedence: 0, lhs: &primaryExpression)
  }

  static func parseBinaryOperation(
    minimalPrecedence: Int,
    lhs: inout ExpressionNode
  ) -> ExpressionNode? {
    while true {
      guard let tokenPrecedence = Parser.precedence(for: currentToken)
      where tokenPrecedence >= minimalPrecedence
      else { return lhs }

      guard case let Token.other(binaryOperator) = currentToken else {
        fatalError("Extracting associated value from enumeration case failed.")
      }
      currentToken = Lexer.nextToken()

      guard var rhs = parsePrimaryExpression() else { return nil }

      if let laterTokenPrecedence = precedence(for: currentToken)
      where laterTokenPrecedence > tokenPrecedence {
        guard let rhsBuffer = parseBinaryOperation(
          minimalPrecedence: tokenPrecedence + 1,
          lhs: &rhs)
        else { return nil }
        rhs = rhsBuffer
      }

      lhs = BinaryExpressionNode(
        operator: binaryOperator,
        arguments: (lhs: lhs, rhs: rhs)
      )
    }
  }
}
