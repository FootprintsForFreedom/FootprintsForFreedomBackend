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
                .create()
            
            try await db.schema(EditableTextObjectModel.schema)
                .id()
                .field(EditableTextObjectModel.FieldKeys.v1.value, .string, .required)
            
                .field(EditableTextObjectModel.FieldKeys.v1.previousId, .uuid)
                .foreignKey(EditableTextObjectModel.FieldKeys.v1.previousId, references: EditableTextObjectModel.schema, .id, onDelete: .setNull)
                .unique(on: EditableTextObjectModel.FieldKeys.v1.previousId)
            
                .field(EditableTextObjectModel.FieldKeys.v1.currentObjectInListWithId, .uuid)
                .foreignKey(EditableTextObjectModel.FieldKeys.v1.currentObjectInListWithId, references: EditableTextRepositoryModel.schema, .id, onDelete: .cascade)
                .unique(on: EditableTextObjectModel.FieldKeys.v1.currentObjectInListWithId)
            
                .field(EditableTextObjectModel.FieldKeys.v1.lastObjectInListWithId, .uuid)
                .foreignKey(EditableTextObjectModel.FieldKeys.v1.lastObjectInListWithId, references: EditableTextRepositoryModel.schema, .id, onDelete: .cascade)
                .unique(on: EditableTextObjectModel.FieldKeys.v1.lastObjectInListWithId)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(EditableTextObjectModel.schema).delete()
            try await db.schema(EditableTextRepositoryModel.schema).delete()
        }
    }
}
