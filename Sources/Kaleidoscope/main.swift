//
//  main.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 11.09.19.
//

import KaleidoscopeLib
import CLLVM
import Foundation

// Helper for converting proper booleans back into numbers.
extension BinaryInteger {
    
    init(_ bool: Bool) {
        self.init()
        self = bool ? 1 : 0
    }
}

guard CommandLine.arguments.count == 2 else {
    print("usage: kalc <file>")
    exit(1)
}

do {
    let file = CommandLine.arguments[1]
    let program = try String(contentsOfFile: file)
    let lexer = Lexer(text: program)
    let parser = Parser(tokens: lexer)
    let ast = try parser.parseFile()
    let irGenerator = IRGenerator(ast: ast)

    try irGenerator.emit()
    
    var verificationError: UnsafeMutablePointer<Int8>?
    let errorStatus = LLVMVerifyModule(irGenerator.module, LLVMReturnStatusAction, &verificationError)
    if let message = verificationError, errorStatus == LLVMBool(true) {
        print(String(cString: message))
        exit(1)
    }
    
    LLVMDumpModule(irGenerator.module)
} catch {
    print(error)
}
