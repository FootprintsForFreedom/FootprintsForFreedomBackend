//
//  AsyncHookFunction.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// Protocol that enables to asynchronously invoke hook functions.
protocol AsyncHookFunction {
    
    /// Asynchronously invoke the hook function.
    /// - Parameter arguments: The arguments passed to the hook function.
    /// - Returns: The return type of the hook function.
    func invokeAsync(_ arguments: HookArguments) async throws -> Any
}

/// The async hook function type which takes ``HookArguments`` and returns the generic return type.
typealias AsyncHookFunctionSignature<T> = (HookArguments) async throws -> T
