//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension Application {

    func invokeAsync<ReturnType>(_ name: String, args: HookArguments = [:]) async throws -> ReturnType? {
        let ctxArgs = args.merging(["app": self]) { (_, new) in new }
        return try await hooks.invokeAsync(name, args: ctxArgs)
    }

    func invokeAllAsync<ReturnType>(_ name: String, args: HookArguments = [:]) async throws -> [ReturnType] {
        let ctxArgs = args.merging(["app": self]) { (_, new) in new }
        return try await hooks.invokeAllAsync(name, args: ctxArgs)
    }
}
