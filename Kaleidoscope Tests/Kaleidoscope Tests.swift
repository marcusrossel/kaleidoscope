//
//  Kaleidoscope Tests.swift
//  Kaleidoscope Tests
//
//  Created by Marcus Rossel on 14.09.16.
//  Copyright © 2016 Marcus Rossel. All rights reserved.
//

import XCTest

class KaleidoscopeTests: XCTestCase {
  let lexer = Lexer()

  func testLexer() {
    // Test numbers.
    lexer.text = "12__34.0_12 -123 0xEEE 0o123 0b1101"
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(1234.012))
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(-123))
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(0xEEE))
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(0o123))
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(0b1101))

    // Reset `lexer`.
    lexer.position = 0

    // Test identifiers.
    lexer.text = "_123 a_23 aSDf_ EE12FA"
    XCTAssertEqual(lexer.nextToken(), .identifier("_123"))
    XCTAssertEqual(lexer.nextToken(), .identifier("a_23"))
    XCTAssertEqual(lexer.nextToken(), .identifier("aSDf_"))
    XCTAssertEqual(lexer.nextToken(), .identifier("EE12FA"))

    // Reset `lexer`.
    lexer.position = 0

    // Test keywords.
    lexer.text = "var extern func function external variable"
    XCTAssertEqual(lexer.nextToken(), .variableKeyword)
    XCTAssertEqual(lexer.nextToken(), .externalKeyword)
    XCTAssertEqual(lexer.nextToken(), .functionKeyword)
    XCTAssertEqual(lexer.nextToken(), .identifier("function"))
    XCTAssertEqual(lexer.nextToken(), .identifier("external"))
    XCTAssertEqual(lexer.nextToken(), .identifier("variable"))

    // Reset `lexer`.
    lexer.position = 0

    // Test comments.
    lexer.text = "a/*abc 123 _?*/bc // To EOL \n 123/*\n*/456"
    XCTAssertEqual(lexer.nextToken(), .identifier("a"))
    XCTAssertEqual(lexer.nextToken(), .identifier("bc"))
    XCTAssertEqual(lexer.nextToken(), .other("\n"))
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(123))
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(456))

    // Reset `lexer`.
    lexer.position = 0

    // Test other.
    lexer.text = "123_._45 ?? \n"
    XCTAssertEqual(lexer.nextToken(), .numberLiteral(123))
    XCTAssertEqual(lexer.nextToken(), .other("."))
    XCTAssertEqual(lexer.nextToken(), .identifier("_45"))
    XCTAssertEqual(lexer.nextToken(), .other("?"))
    XCTAssertEqual(lexer.nextToken(), .other("?"))
    XCTAssertEqual(lexer.nextToken(), .other("\n"))
  }
}
