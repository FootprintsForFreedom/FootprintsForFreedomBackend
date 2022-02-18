//
//  EditableTextMigrations.swift
//  
//
//  Created by niklhut on 10.02.22.
//

import Vapor
import Fluent

enum EditableTextMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(EditableTextRepositoryModel.schema)
                .id()
            
                .field(EditableTextRepositoryModel.FieldKeys.v1.currentId, .uuid)
                .foreignKey(EditableTextRepositoryModel.FieldKeys.v1.currentId, references: EditableTextObjectModel.schema, .id, onDelete: .setNull)
                .unique(on: EditableTextRepositoryModel.FieldKeys.v1.currentId)
            
                .field(EditableTextRepositoryModel.FieldKeys.v1.lastId, .uuid)
                .foreignKey(EditableTextRepositoryModel.FieldKeys.v1.lastId, references: EditableTextObjectModel.schema, .id, onDelete: .setNull)
                .unique(on: EditableTextRepositoryModel.FieldKeys.v1.lastId)
            
                .create()
            
            try await db.schema(EditableTextObjectModel.schema)
                .id()
                .field(EditableTextObjectModel.FieldKeys.v1.value, .string, .required)
            
                .field(EditableTextObjectModel.FieldKeys.v1.previousId, .uuid)
                .foreignKey(EditableTextObjectModel.FieldKeys.v1.previousId, references: EditableTextObjectModel.schema, .id, onDelete: .setNull)
                .unique(on: EditableTextObjectModel.FieldKeys.v1.previousId)
            
                .field(EditableTextObjectModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(EditableTextObjectModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id)
            
                .field(EditableTextObjectModel.FieldKeys.v1.createdAt, .datetime, .required)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(EditableTextObjectModel.schema).delete()
            try await db.schema(EditableTextRepositoryModel.schema).delete()
        }
    }
}
