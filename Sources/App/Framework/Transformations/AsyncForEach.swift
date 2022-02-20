//
//  AsyncForEach.swift
//  
//
//  Created by niklhut on 19.02.22.
//

import Foundation

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
}
