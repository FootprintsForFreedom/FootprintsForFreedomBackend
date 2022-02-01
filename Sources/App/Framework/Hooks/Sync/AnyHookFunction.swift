//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

struct AnyHookFunction: HookFunction {

    private let functionBlock: HookFunctionSignature<Any>

    init(_ functionBlock: @escaping HookFunctionSignature<Any>) {
        self.functionBlock = functionBlock
    }

    func invoke(_ args: HookArguments) -> Any {
        functionBlock(args)
    }
}
