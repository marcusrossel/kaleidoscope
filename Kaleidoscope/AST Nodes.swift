//
//  AST Nodes.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 09.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import Foundation

protocol ExpressionNode { }

struct NumberExpressionNode: ExpressionNode {
  let value: Double
}

struct VariableExpressionNode: ExpressionNode {
  let name: String
}

struct BinaryExpressionNode: ExpressionNode {
  var `operator`: Character
  var arguments: (lhs: ExpressionNode, rhs: ExpressionNode)
}

struct CallExpressionNode: ExpressionNode {
  var callee: String
  var arguments: [ExpressionNode]
}

struct PrototypeNode {
  var name: String
  // Currently the only real type is `Number`, so the argument names are enough.
  var arguments: [String]
}

struct FunctionNode {
  var head: PrototypeNode
  var body: ExpressionNode
}
