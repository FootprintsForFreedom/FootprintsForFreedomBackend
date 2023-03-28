//
//  AnyHookFunction.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// A synchronous hook function.
struct AnyHookFunction: HookFunction {
    
    /// The actual hook function.
    private let functionBlock: HookFunctionSignature<Any>
    
    /// Initialize a synchronous hook function.
    /// - Parameter functionBlock: The action to perform when executing the hook function.
    init(_ functionBlock: @escaping HookFunctionSignature<Any>) {
        self.functionBlock = functionBlock
    }
    
    func invoke(_ args: HookArguments) -> Any {
        functionBlock(args)
    }
}
