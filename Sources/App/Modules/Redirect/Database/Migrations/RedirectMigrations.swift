//
//  RedirectMigrations.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Vapor
import Fluent

enum RedirectMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(RedirectModel.schema)
                .id()
            
                .field(RedirectModel.FieldKeys.v1.source, .string, .required)
                .unique(on: RedirectModel.FieldKeys.v1.source)
            
                .field(RedirectModel.FieldKeys.v1.destination, .string, .required)
            
                .field(RedirectModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(RedirectModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(RedirectModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(RedirectModel.schema).delete()
        }
    }
}
