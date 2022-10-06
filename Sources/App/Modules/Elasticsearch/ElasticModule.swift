//
//  ElasticModule.swift
//  
//
//  Created by niklhut on 27.09.22.
//

import Vapor
import ElasticsearchNIOClient

struct ElasticModule: ModuleInterface {
    static let models: [any ElasticModelInterface.Type] = [
        LatestVerifiedTagModel.Elasticsearch.self,
        WaypointSummaryModel.Elasticsearch.self
    ]
    
    @discardableResult
    static func createIndex(for languageCode: String, on elastic: ElasticHandler) async throws -> [ESDeleteIndexResponse] {
        try await models.concurrentMap { try await $0.createIndex(for: languageCode, on: elastic)}
    }
    
    @discardableResult
    static func deactivateLanguage(_ language: LanguageModel, on elastic: ElasticHandler) async throws -> [ESDeleteIndexResponse] {
        try await models.concurrentMap { try await $0.deactivateLanguage(language, on: elastic) }
    }
    
    @discardableResult
    static func activateLanguage(_ language: LanguageModel, on req: Request) async throws -> [ESBulkResponse?] {
        try await models.concurrentMap { try await $0.activateLanguage(language, on: req)}
    }
    
    @discardableResult
    static func updateLanguages(_ languageIds: [UUID], on req: Request) async throws -> [ESBulkResponse?] {
        try await models.concurrentMap { try await $0.updateLanguages(languageIds, on: req) }
    }
    
    @discardableResult
    static func deleteUser(_ userId: UUID, on req: Request) async throws -> [ESBulkResponse?] {
        try await models.concurrentMap { try await $0.deleteUser(userId, on: req)}
    }
}
