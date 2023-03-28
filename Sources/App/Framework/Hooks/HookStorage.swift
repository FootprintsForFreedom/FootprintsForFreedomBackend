//
//  HookStorage.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// Stores all synchronous and asynchronous hooks.
final class HookStorage {
    
    /// The pointers to the synchronous hook functions.
    var pointers: [HookFunctionPointer<HookFunction>]
    /// The pointers to the asynchronous hook functions.
    var asyncPointers: [HookFunctionPointer<AsyncHookFunction>]
    
    init() {
        self.pointers = []
        self.asyncPointers = []
    }    
}

