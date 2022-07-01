//
//  Application+HookStorage.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension Application {
    
    /// The key to the application hook storage
    private struct HookStorageKey: StorageKey {
        typealias Value = HookStorage
    }
    
    /// The hooks for this application.
    var hooks: HookStorage {
        get {
            if let existing = storage[HookStorageKey.self] {
                return existing
            }
            let new = HookStorage()
            storage[HookStorageKey.self] = new
            return new
        }
        set {
            storage[HookStorageKey.self] = newValue
        }
    }
}
