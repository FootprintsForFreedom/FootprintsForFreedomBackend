//
//  HookFunction.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// Protocol that enables to synchronously invoke hook functions.
protocol HookFunction {
    
    /// Synchronously invoke the hook function.
    /// - Parameter arguments: The arguments passed to the hook function.
    /// - Returns: The return type of the hook function.
    func invoke(_ arguments: HookArguments) -> Any
}

/// The synchronous  hook function type which takes ``HookArguments`` and returns the generic return type.
typealias HookFunctionSignature<T> = (HookArguments) -> T
