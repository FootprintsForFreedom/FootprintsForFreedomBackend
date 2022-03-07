//
//  StorableMigrations.swift
//  
//
//  Created by niklhut on 10.02.22.
//

import Vapor
import Fluent

enum StorableMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(StorableObjectModel<String>.schema)
                .id()
                .field(StorableObjectModel<String>.FieldKeys.v1.value, .data, .required)
            
                .field(StorableObjectModel<String>.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(StorableObjectModel<String>.FieldKeys.v1.userId, references: UserAccountModel.schema, .id)
            
                .field(StorableObjectModel<String>.FieldKeys.v1.createdAt, .datetime, .required)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(StorableObjectModel<String>.schema).delete()
        }
    }
}
