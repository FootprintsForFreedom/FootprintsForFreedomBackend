//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

final class HookStorage {

    var pointers: [HookFunctionPointer<HookFunction>]
    var asyncPointers: [HookFunctionPointer<AsyncHookFunction>]

    init() {
        self.pointers = []
        self.asyncPointers = []
    }    
}

