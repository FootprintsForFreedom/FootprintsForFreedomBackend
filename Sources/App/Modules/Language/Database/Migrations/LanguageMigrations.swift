//
//  LanguageMigrations.swift
//  
//
//  Created by niklhut on 03.03.22.
//

import Vapor
import Fluent

enum LanguageMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            try await db.schema(LanguageModel.schema)
                .id()
            
                .field(LanguageModel.FieldKeys.v1.languageCode, .string, .required)
                .unique(on: LanguageModel.FieldKeys.v1.languageCode)
            
                .field(LanguageModel.FieldKeys.v1.name, .string, .required)
                .unique(on: LanguageModel.FieldKeys.v1.name)
            
                .field(LanguageModel.FieldKeys.v1.officialName, .string, .required)
            
                .field(LanguageModel.FieldKeys.v1.isRTL, .bool, .required)
            
                .field(LanguageModel.FieldKeys.v1.priority, .int64)
                .unique(on: LanguageModel.FieldKeys.v1.priority)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(LanguageModel.schema).delete()
        }
    }
    
    struct seed: AsyncMigration {
        let elastic: ElasticHandler
        
        func prepare(on db: Database) async throws {
            let languageCode = "de"
            let priority = 1
            let language = try LanguageModel(
                languageCode: languageCode,
                priority: priority
            )
            try await language.create(on: db)
            try await ElasticModule.createIndex(for: languageCode, on: elastic)
        }
        
        func revert(on db: Database) async throws {
            try await LanguageModel.query(on: db).delete()
        }
    }
}
