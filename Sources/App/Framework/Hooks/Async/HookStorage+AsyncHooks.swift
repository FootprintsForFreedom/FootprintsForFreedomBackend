//
//  HookStorage+AsyncHooks.swift
//  
//
//  Created by niklhut on 01.02.22.
//

extension HookStorage {
    
    /// Asynchronously register a kook function.
    /// - Parameters:
    ///   - name: The name of the hook function.
    ///   - block: The hook function block.
    func registerAsync<ReturnType>(_ name: String, use block: @escaping AsyncHookFunctionSignature<ReturnType>) {
        let function = AsyncAnyHookFunction { args -> Any in
            try await block(args)
        }
        let pointer = HookFunctionPointer<AsyncHookFunction>(name: name, function: function, returnType: ReturnType.self)
        asyncPointers.append(pointer)
    }
    
    /// Asynchronously invoke the first hook function with the given name.
    /// - Parameters:
    ///   - name: The name of the hook function to invoke.
    ///   - args: The hook arguments passed to the hook function.
    /// - Returns: The returned value from the invoked hook function.
    func invokeAsync<ReturnType>(_ name: String, args: HookArguments = [:]) async throws -> ReturnType? {
        try await asyncPointers.first { $0.name == name && $0.returnType == ReturnType.self }?.pointer.invokeAsync(args) as? ReturnType
    }
    
    /// Asynchronously invoke all hook functions with the given name.
    /// - Parameters:
    ///   - name: The name of the hook function to invoke.
    ///   - args: The hook arguments passed to the hook function.
    /// - Returns: An array of the return values of all hook functions with the given name.
    func invokeAllAsync<ReturnType>(_ name: String, args: HookArguments = [:]) async throws -> [ReturnType] {
        let fns = asyncPointers.filter { $0.name == name && $0.returnType == ReturnType.self }
        var result: [ReturnType] = []
        for fn in fns {
            if let res = try await fn.pointer.invokeAsync(args) as? ReturnType {
                result.append(res)
            }
        }
        return result
    }
}
