import XCTest
@testable import Kaleidoscope

final class LexerTests: XCTestCase {

    var lexer = Lexer()
    lazy var parser = Parser(tokens: lexer)
    
    static var allTests = [
        ("testLexer", testLexer),
    ]
    
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
        lexer.text = "_123 a_23 aSDf_ EE12F:A"
        XCTAssertEqual(lexer.nextToken(), .identifier("_123"))
        XCTAssertEqual(lexer.nextToken(), .identifier("a_23"))
        XCTAssertEqual(lexer.nextToken(), .identifier("aSDf_"))
        XCTAssertEqual(lexer.nextToken(), .identifier("EE12F"))
        XCTAssertEqual(lexer.nextToken(), .other(":"))
        XCTAssertEqual(lexer.nextToken(), .identifier("A"))
        
        // Reset `lexer`.
        lexer.position = 0
        
        // Test keywords.
        lexer.text = "extern func function if external then else"
        XCTAssertEqual(lexer.nextToken(), .keyword(.external))
        XCTAssertEqual(lexer.nextToken(), .keyword(.function))
        XCTAssertEqual(lexer.nextToken(), .identifier("function"))
        XCTAssertEqual(lexer.nextToken(), .keyword(.if))
        XCTAssertEqual(lexer.nextToken(), .identifier("external"))
        XCTAssertEqual(lexer.nextToken(), .keyword(.then))
        XCTAssertEqual(lexer.nextToken(), .keyword(.else))
        
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
        
        // Test single character tokens.
        lexer.text = "+ - * / % = , ; ( )"
        XCTAssertEqual(lexer.nextToken(), .operator(.plus))
        XCTAssertEqual(lexer.nextToken(), .operator(.minus))
        XCTAssertEqual(lexer.nextToken(), .operator(.times))
        XCTAssertEqual(lexer.nextToken(), .operator(.divide))
        XCTAssertEqual(lexer.nextToken(), .operator(.modulo))
        XCTAssertEqual(lexer.nextToken(), .operator(.equals))
        XCTAssertEqual(lexer.nextToken(), .symbol(.comma))
        XCTAssertEqual(lexer.nextToken(), .symbol(.semicolon))
        XCTAssertEqual(lexer.nextToken(), .symbol(.leftParenthesis))
        XCTAssertEqual(lexer.nextToken(), .symbol(.rightParenthesis))
        
        // Reset `lexer`.
        lexer.position = 0
        
        // Test other.
        lexer.text = "123_._45 ?? \n"
        XCTAssertEqual(lexer.nextToken(), .numberLiteral(123))
        XCTAssertEqual(lexer.nextToken(), .other("_"))
        XCTAssertEqual(lexer.nextToken(), .other("."))
        XCTAssertEqual(lexer.nextToken(), .identifier("_45"))
        XCTAssertEqual(lexer.nextToken(), .other("?"))
        XCTAssertEqual(lexer.nextToken(), .other("?"))
        XCTAssertEqual(lexer.nextToken(), .other("\n"))
        XCTAssertEqual(lexer.nextToken(), .endOfFile)
    }

}
