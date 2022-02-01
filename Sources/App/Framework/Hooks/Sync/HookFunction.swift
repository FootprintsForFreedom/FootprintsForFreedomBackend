//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//


protocol HookFunction {
    func invoke(_: HookArguments) -> Any
}

typealias HookFunctionSignature<T> = (HookArguments) -> T
