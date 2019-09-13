//
//  main.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 11.09.19.
//

import KaleidoscopeLib

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
let ast = try parser.parseFile()

print(ast)



import CLLVM

// Helper for converting proper booleans back into numbers.
extension BinaryInteger {
    
    init(_ bool: Bool) {
        self.init()
        self = bool ? 1 : 0
    }
}

let module: LLVMModuleRef = LLVMModuleCreateWithName("main")

var parameters: [LLVMTypeRef?] = [LLVMInt32Type(), LLVMInt32Type()]

let prototype: LLVMTypeRef = LLVMFunctionType(
    LLVMInt32Type(),
    &parameters,
    UInt32(parameters.count),
    LLVMBool(false)
)

let function: LLVMValueRef = LLVMAddFunction(module, "sum", prototype)

let entry: LLVMBasicBlockRef = LLVMAppendBasicBlock(function, "entry")

let builder: LLVMBuilderRef = LLVMCreateBuilder()

LLVMPositionBuilderAtEnd(builder, entry)

let result: LLVMValueRef = LLVMBuildAdd(
    builder,
    LLVMGetParam(function, 0),
    LLVMGetParam(function, 1),
    "result"
)

LLVMBuildRet(builder, result)

var error: UnsafeMutablePointer<Int8>?

LLVMVerifyModule(
    module,
    LLVMAbortProcessAction,
    &error
)

if let error = error { LLVMDisposeMessage(error) }

error = nil

if (LLVMWriteBitcodeToFile(module, "/Users/marcus/Desktop/a.bc") != 0) {
    fatalError("Error emitting bitcode.")
}

/*
var engine: LLVMExecutionEngineRef?

LLVMLinkInMCJIT()
LLVMInitializeNativeTarget()

if (LLVMCreateExecutionEngineForModule(&engine, module, &error) != 0) {
    fatalError("Failed to create execution engine.")
}

if let error = error {
    print("Error: \(error)")
    LLVMDisposeMessage(error)
    fatalError()
}

var arguments: [LLVMGenericValueRef?] = [
    LLVMCreateGenericValueOfInt(LLVMInt32Type(), 12, LLVMBool(false)),
    LLVMCreateGenericValueOfInt(LLVMInt32Type(), 42, LLVMBool(false))
]

let output: LLVMGenericValueRef = LLVMRunFunction(
    engine,
    function,
    UInt32(arguments.count),
    &arguments
)

let usableOutput: UInt64 = LLVMGenericValueToInt(output, LLVMBool(false))

print("\(usableOutput)")
*/
