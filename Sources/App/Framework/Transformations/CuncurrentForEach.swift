//
//  CuncurrentForEach.swift
//  
//
//  Created by niklhut on 19.02.22.
//

import Foundation

extension Sequence {
    func concurrentForEach(
        _ operation: @escaping (Element) async throws -> Void
    ) async {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
        }
    }
}
