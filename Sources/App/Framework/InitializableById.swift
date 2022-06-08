//
//  InitializableById.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Fluent

protocol InitializableById: Codable {
    init?(id: UUID?, db: Database) async throws
}
