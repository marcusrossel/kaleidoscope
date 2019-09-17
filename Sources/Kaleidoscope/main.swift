//
//  main.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 11.09.19.
//

import KaleidoscopeLib
import CLLVM

let program = """
//
// An example program in the Kaleidoscope language.
//

extern printf(string);
extern run(start, increment);

double(3.141 + 2.718)

func double(x) (2 * x);
func max(x, y) if (x - y) then (x) else (y);
"""

let lexer = Lexer(text: program)
let parser = Parser(tokens: lexer)
let file = try parser.parseFile()
let irGenerator = IRGenerator(file: file)
try irGenerator.emit()
LLVMDumpModule(irGenerator.module)
