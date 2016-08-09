//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 08.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

class Parser {
  static var currentToken = Lexer.nextToken()

  static func parseNumberExpression() -> ExpressionNode? {
    guard case let Lexer.Token.number(number) = currentToken else {
      print("Parses Error: Called \(#function) on inappropriate token.")
      return nil
    }
    defer { currentToken = Lexer.nextToken() }
    return NumberExpressionNode(value: number)
  }

  static func parseParenthesesExpression() -> ExpressionNode? {
    guard case Lexer.Token.other("(") = currentToken else {
      print("Parses Error: Called \(#function) on inappropriate token.")
      return nil
    }
    currentToken = Lexer.nextToken()

    guard let enclosedExpression = Parser.parseExpression() else { return nil }

    guard case Lexer.Token.other(")") = currentToken else {
      print("Syntax Error: Expected `)`.")
      return nil
    }

    currentToken = Lexer.nextToken()
    return enclosedExpression
  }

  /*THINK THROUGH THIS*/
  static func parseIdentifierExpression() -> ExpressionNode? {
    guard case let Lexer.Token.identifier(identifier) = currentToken else {
      print("Parses Error: Called \(#function) on inappropriate token.")
      return nil
    }
    currentToken = Lexer.nextToken()

    guard case Lexer.Token.other("(") = currentToken else {
      return VariableExpressionNode(name: identifier)
    }
    currentToken = Lexer.nextToken()

    var arguments = [ExpressionNode]()

    if case Lexer.Token.other(")") = currentToken { } else {
      while true {
        guard let argument = parseExpression() else { return nil }
        arguments.append(argument)

        if case Lexer.Token.other(")") = currentToken { break }

        if case Lexer.Token.other(",") = currentToken { } else {
          print("Syntax Error: Expected `)` or `,` in argument list.")
          return nil
        }

        currentToken = Lexer.nextToken()
      }
    }

    currentToken = Lexer.nextToken()
    return CallExpressionNode(callee: identifier, arguments: arguments)
  }


  // Surpress compiler error.
  static func parseExpression() -> ExpressionNode? { return nil }
}
