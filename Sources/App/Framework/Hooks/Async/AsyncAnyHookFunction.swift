//
//  AsyncAnyHookFunction.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// An asynchronous hook function.
struct AsyncAnyHookFunction: AsyncHookFunction {
    
    /// The actual hook function.
    private let functionBlock: AsyncHookFunctionSignature<Any>
    
    /// Initialize an asynchronous hook function.
    /// - Parameter functionBlock: The action to perform when executing the hook function.
    init(_ functionBlock: @escaping AsyncHookFunctionSignature<Any>) {
        self.functionBlock = functionBlock
    }
    
    func invokeAsync(_ args: HookArguments) async throws -> Any {
        try await functionBlock(args)
    }
}
