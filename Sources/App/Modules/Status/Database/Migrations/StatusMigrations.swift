//
//  StatusMigrations.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Vapor
import Fluent

enum StatusMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let _ = try await db.enum(Status.pathKey)
                .case(Status.pending.rawValue)
                .case(Status.verified.rawValue)
                .case(Status.deleteRequested.rawValue)
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.enum(Status.pathKey).delete()
        }
    }
}
