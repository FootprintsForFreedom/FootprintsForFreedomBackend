//
//  EditableObjectMigrations.swift
//  
//
//  Created by niklhut on 10.02.22.
//

import Vapor
import Fluent

enum EditableObjectMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(EditableObjectModel<String>.schema)
                .id()
                .field(EditableObjectModel<String>.FieldKeys.v1.value, .data, .required)
            
                .field(EditableObjectModel<String>.FieldKeys.v1.previousId, .uuid)
                .foreignKey(EditableObjectModel<String>.FieldKeys.v1.previousId, references: EditableObjectModel<String>.schema, .id, onDelete: .setNull)
                .unique(on: EditableObjectModel<String>.FieldKeys.v1.previousId)
            
                .field(EditableObjectModel<String>.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(EditableObjectModel<String>.FieldKeys.v1.userId, references: UserAccountModel.schema, .id)
            
                .field(EditableObjectModel<String>.FieldKeys.v1.createdAt, .datetime, .required)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(EditableObjectModel<String>.schema).delete()
        }
    }
}
