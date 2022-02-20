//
//  CuncurrentMap.swift
//  
//
//  Created by niklhut on 19.02.22.
//

import Foundation

extension Sequence {
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
                try await transform(element)
            }
        }
        
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}
