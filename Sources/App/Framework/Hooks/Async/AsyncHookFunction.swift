//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

protocol AsyncHookFunction {
    func invokeAsync(_: HookArguments) async throws -> Any
}

typealias AsyncHookFunctionSignature<T> = (HookArguments) async throws -> T
