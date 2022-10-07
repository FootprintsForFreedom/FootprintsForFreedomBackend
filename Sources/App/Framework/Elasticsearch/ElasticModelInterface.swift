//
//  ElasticModelInterface.swift
//  
//
//  Created by niklhut on 15.09.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient
import ISO639

protocol ElasticModelInterface: Codable where DatabaseModel.ElasticModel == Self {
    associatedtype DatabaseModel: DatabaseElasticInterface
    associatedtype Key: Codable, LockKey
    associatedtype IDValue: Hashable
    static var baseSchema: String { get }
    static var mappings: [String: Any] { get }
    
    var id: UUID { get }
    var languageId: IDValue { get }
    var languageCode: String { get }
    var detailUserId: IDValue? { get set }
    
    var schema: String { get }
    static var wildcardSchema: String { get }
    static func schema(for languageCode: String) -> String
    
    @discardableResult
    static func createOrUpdate(detailWithId detailId: UUID, on req: Request) async throws -> ESUpdateDocumentResponse<String>?
    @discardableResult
    static func delete(allDetailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse
    
    
    @discardableResult
    static func createIndex(for languageCode: String, on elastic: ElasticHandler) async throws -> ESDeleteIndexResponse
    
    @discardableResult
    static func deactivateLanguage(_ languageCode: String, on elastic: ElasticHandler) async throws -> ESDeleteIndexResponse
    @discardableResult
    static func activateLanguage(_ languageCode: String, on req: Request) async throws -> ESBulkResponse?
    @discardableResult
    static func updateLanguages(_ languageCodes: [String], on req: Request) async throws -> ESBulkResponse?
    
    @discardableResult
    static func deleteUser(_ userId: UUID, on req: Request) async throws -> ESBulkResponse?
}

extension ElasticModelInterface {
    var schema: String {
        Self.baseSchema.appending("_\(languageCode)")
    }
    
    static var wildcardSchema: String {
        Self.baseSchema.appending("*")
    }
    
    static func schema(for languageCode: String) -> String {
        return Self.baseSchema.appending("_\(languageCode)")
    }
    
    @discardableResult
    static func createOrUpdate(detailWithId detailId: UUID, on req: Request) async throws -> ESUpdateDocumentResponse<String>? {
        guard let element = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$detailId == detailId)
            .first()
        else {
            return nil
        }
        let document = try await element.toElasticsearch(on: req.db)
        let response = try req.elastic.createOrUpdate(document)
        return response
    }
    
    @discardableResult
    static func delete(allDetailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse {
        let languages = try await LanguageModel.query(on: req.db).all()
        let elementsToDelete = languages
            .map { ESBulkOperation<Self, String>(operationType: .delete, index: Self.schema(for: $0.languageCode), id: repositoryId.uuidString, document: nil) }
        return try req.elastic.bulk(elementsToDelete)
    }
    
    @discardableResult
    static func createIndex(for languageCode: String, on elastic: ElasticHandler) async throws -> ESDeleteIndexResponse {
        guard let language = Language.from(with: languageCode) else { throw Abort(.internalServerError) }
        return try await elastic.createIndex(Self.schema(for: languageCode), mappings: Self.mappings, settings: language.analyzer.json)
    }
    
    @discardableResult
    static func deactivateLanguage(_ languageCode: String, on elastic: ElasticHandler) async throws -> ESDeleteIndexResponse {
        try await elastic.deleteIndex(Self.schema(for: languageCode))
    }
    
    @discardableResult
    static func activateLanguage(_ languageCode: String, on req: Request) async throws -> ESBulkResponse? {
        try await createIndex(for: languageCode, on: req.elastic)
        
        let elementsToActivate = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$languageCode == languageCode)
            .all()
        
        guard !elementsToActivate.isEmpty else { return nil }
        let documents = try await elementsToActivate
            .concurrentMap { try await $0.toElasticsearch(on: req.db) }
            .map { ESBulkOperation(operationType: .create, index: $0.schema, id: $0.id.uuidString, document: $0) }
        return try req.elastic.bulk(documents)
    }
    
    @discardableResult
    static func updateLanguages(_ languageCodes: [String], on req: Request) async throws -> ESBulkResponse? {
        let elementsToChange = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$languageCode ~~ languageCodes)
            .all()
        
        guard !elementsToChange.isEmpty else { return nil }
        let documents = try await elementsToChange
            .concurrentMap { try await $0.toElasticsearch(on: req.db) }
            .map { ESBulkOperation(operationType: .update, index: $0.schema, id: $0.id.uuidString, document: $0) }
        return try req.elastic.bulk(documents)
    }
    
    @discardableResult
    static func deleteUser(_ userId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elementsToDelete = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$detailUserId == userId)
            .all()
        
        guard !elementsToDelete.isEmpty else { return nil }
        let documents = try await elementsToDelete
            .concurrentMap { element in
                var document = try await element.toElasticsearch(on: req.db)
                document.detailUserId = nil
                return document
            }
            .map { (document: Self) in
                return ESBulkOperation(operationType: .update, index: document.schema, id: document.id.uuidString, document: document)
            }
        let response = try req.elastic.bulk(documents)
        return response
    }
}
