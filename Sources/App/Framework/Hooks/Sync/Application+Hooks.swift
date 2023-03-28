//
//  Application+Hooks.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension Application {
    
    /// Synchronously invoke the first hook function with the given name.
    /// - Parameters:
    ///   - name: The name of the hook function to invoke.
    ///   - args: The hook arguments passed to the hook function.
    /// - Returns: The returned value from the invoked hook function.
    func invoke<ReturnType>(_ name: String, args: HookArguments = [:]) -> ReturnType? {
        let ctxArgs = args.merging(["app": self]) { (_, new) in new }
        return hooks.invoke(name, args: ctxArgs)
    }
    
    /// Synchronously invoke all hook functions with the given name.
    /// - Parameters:
    ///   - name: The name of the hook function to invoke.
    ///   - args: The hook arguments passed to the hook function.
    /// - Returns: An array of the return values of all hook functions with the given name.
    func invokeAll<ReturnType>(_ name: String, args: HookArguments = [:]) -> [ReturnType] {
        let ctxArgs = args.merging(["app": self]) { (_, new) in new }
        return hooks.invokeAll(name, args: ctxArgs)
    }
}
