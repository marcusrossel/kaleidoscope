//
//  AST.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 09.08.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

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
