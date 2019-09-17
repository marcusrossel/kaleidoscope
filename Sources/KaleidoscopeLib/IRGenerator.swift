//
//  IRGenerator.swift
//  Kaleidoscope
//
//  Created by Marcus Rossel on 12.09.19.
//

import CLLVM

public final class IRGenerator {
    
    public enum Error: Swift.Error {
        case unknownFunction(name: String)
        case invalidNumberOfArguments(Int, expected: Int)
        case unknownVariable(name: String)
        case verificationFailure(function: String)
        case builderFailure
    }
    
    public init(file: File) {
        self.file = file
        builder = LLVMCreateBuilderInContext(LLVMGetGlobalContext())
        module = LLVMModuleCreateWithName("kaleidoscope")
        namedValues = [:]
        
        floatType = LLVMFloatTypeInContext(LLVMGetGlobalContext())
    }
    
    public private(set) var file: File
    public private(set) var module: LLVMModuleRef
    private let builder: LLVMBuilderRef
    private var namedValues: [String: LLVMValueRef]
    
    private let floatType: LLVMTypeRef
}

extension IRGenerator {
    
    public func emit() throws {
        _ = file.externals.map(emit(prototype:))
        _ = try file.functions.map(emit(function:))
        try emitMain()
    }
    
    private func emitMain() throws {
        var parameters: [LLVMTypeRef?] = []
        let signature = LLVMFunctionType(
            LLVMVoidType(),
            &parameters,
            UInt32(parameters.count),
            LLVMBool(false)
        )
        let main = LLVMAddFunction(module, "main", signature)
        let entryBlock = LLVMAppendBasicBlock(main, "entry")
        LLVMPositionBuilderAtEnd(builder, entryBlock)
        
        let formatString = LLVMBuildGlobalStringPtr(builder, "%f\n", "format")
        let printf = emitPrintf()
        
        for expression in file.expressions {
            let value = try emit(expression: expression)
            var arguments: [LLVMValueRef?] = [value, formatString]
            LLVMBuildCall(builder, printf, &arguments, UInt32(arguments.count), "print")
        }
        
        LLVMBuildRetVoid(builder)
    }
    
    @discardableResult
    private func emitPrintf() -> LLVMValueRef {
        if let predefined = LLVMGetNamedFunction(module, "printf") { return predefined }
        
        var parameters: [LLVMTypeRef?] = [
            LLVMPointerType(LLVMInt8TypeInContext(LLVMGetGlobalContext()), 0)
        ]
        let signature = LLVMFunctionType(
            LLVMInt32Type(),
            &parameters,
            UInt32(parameters.count),
            LLVMBool(true)
        )
        
        return LLVMAddFunction(module, "printf", signature)
    }
    
    @discardableResult
    private func emit(function: Function) throws -> LLVMValueRef {
        let prototype = emit(prototype: function.head)
        let entryBlock = LLVMAppendBasicBlock(prototype, "entry")
        
        // Sets up the symbol table for the function body.
        namedValues.removeAll()
        for (index, name) in function.head.parameters.enumerated() {
            namedValues[name] = LLVMGetParam(prototype, UInt32(index))
        }
        
        LLVMPositionBuilderAtEnd(builder, entryBlock)
        LLVMBuildRet(builder, try emit(expression: function.body))
        
        guard LLVMVerifyFunction(prototype, LLVMAbortProcessAction) == LLVMBool(true) else {
            throw Error.verificationFailure(function: function.head.name)
        }
        
        return prototype
    }

    @discardableResult
    private func emit(prototype: Prototype) -> LLVMValueRef {
        if let predefined = LLVMGetNamedFunction(module, prototype.name) { return predefined }
        
        var parameters = [LLVMTypeRef?](repeating: floatType, count: prototype.parameters.count)
        let signature = LLVMFunctionType(
            floatType,
            &parameters,
            UInt32(prototype.parameters.count),
            LLVMBool(false)
        )
        
        return LLVMAddFunction(module, prototype.name, signature)
    }
    
    @discardableResult
    private func emit(expression: Expression) throws -> LLVMValueRef {
        switch expression {
        case .number(let value):
            return LLVMConstReal(floatType, value)
            
        case .variable(let name):
            guard let value = namedValues[name] else { throw Error.unknownVariable(name: name) }
            return value
                
        case let .call(functionName, arguments: arguments):
            guard let function = LLVMGetNamedFunction(module, functionName) else {
                throw Error.unknownFunction(name: functionName)
            }
            
            let parameterCount = LLVMCountParams(function)
            guard parameterCount == arguments.count else {
                throw Error.invalidNumberOfArguments(Int(parameterCount), expected: arguments.count)
            }
            
            var arguments: [LLVMValueRef?] = try arguments.map(emit(expression:))
            
            return LLVMBuildCall(builder, function, &arguments, parameterCount, functionName)
            
        case let .binary(lhs: lhs, operator: `operator`, rhs: rhs):
            let lhs = try emit(expression: lhs)
            let rhs = try emit(expression: rhs)
            
            switch `operator` {
            case .plus:
                return LLVMBuildFAdd(builder, lhs, rhs, "sum")
            case .minus:
                return LLVMBuildFSub(builder, lhs, rhs, "difference")
            case .times:
                return LLVMBuildFMul(builder, lhs, rhs, "product")
            case .divide:
                return LLVMBuildFDiv(builder, lhs, rhs, "quotient")
            case .modulo:
                return LLVMBuildFRem(builder, lhs, rhs, "remainder")
            case .equals:
                let bool = LLVMBuildFCmp(builder, LLVMRealUEQ, lhs, rhs, "equality")
                return LLVMBuildCast(builder, LLVMUIToFP, bool, floatType, "floatedBool")
            }
            
        case let .if(condition: condition, then: then, else: `else`):            
            let mergeBlock = LLVMCreateBasicBlockInContext(LLVMGetGlobalContext(), "merge")
        
            let thenBlock = LLVMCreateBasicBlockInContext(LLVMGetGlobalContext(), "then")
            LLVMBuildBr(builder, mergeBlock)
            
            let elseBlock = LLVMCreateBasicBlockInContext(LLVMGetGlobalContext(), "else")
            LLVMBuildBr(builder, mergeBlock)
            
            let ifBlock = LLVMCreateBasicBlockInContext(LLVMGetGlobalContext(), "if")
            let condition = try emit(expression: condition)
            let floatForFalse = LLVMConstReal(floatType, Double(Int(false)))
            let ifHeader = LLVMBuildFCmp(builder, LLVMRealONE, condition, floatForFalse, "condition")
            LLVMBuildCondBr(builder, ifHeader, thenBlock, elseBlock)
            
            // Move the instructions and blocks into the right order.
            LLVMMoveBasicBlockAfter(mergeBlock, elseBlock)
            LLVMMoveBasicBlockBefore(ifBlock, thenBlock)
            
            guard let resultPhi = LLVMBuildPhi(builder, floatType, "result") else {
                throw Error.builderFailure
            }
            var phiValues: [LLVMValueRef?] = [
                try emit(expression: then),
                try emit(expression: `else`)
            ]
            var phiBlocks = [thenBlock, elseBlock]
            LLVMAddIncoming(resultPhi, &phiValues, &phiBlocks, UInt32(phiValues.count))
            
            return resultPhi
        }
    }
}

// Helper for converting proper booleans back into numbers.
extension BinaryInteger {
    
    init(_ bool: Bool) {
        self.init()
        self = bool ? 1 : 0
    }
}
