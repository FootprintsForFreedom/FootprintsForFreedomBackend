//
//  Page+ConcurrentMap.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import FluentKit

extension Page {
    func concurrentMap<U>(_ transform: @escaping (T) async throws -> (U)) async throws -> Page<U> {
        try await .init(
            items: self.items.concurrentMap(transform),
            metadata: self.metadata)
    }
    
    func compactMap<U>(_ transform: (T) throws -> U?) rethrows -> Page<U> {
        .init(
            items: try self.items.compactMap(transform),
            metadata: self.metadata
        )
    }
    
    func concurrentCompactMap<U>(_ transform: @escaping (T) async throws -> U?) async throws -> Page<U> {
        try await .init(
            items: self.items.concurrentCompactMap(transform),
            metadata: self.metadata)
    }
}

