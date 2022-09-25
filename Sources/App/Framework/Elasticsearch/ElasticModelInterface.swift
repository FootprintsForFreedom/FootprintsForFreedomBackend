//
//  ElasticModelInterface.swift
//  
//
//  Created by niklhut on 15.09.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

protocol ElasticModelInterface: Codable where DatabaseModel.ElasticModel == Self {
    associatedtype DatabaseModel: DatabaseElasticInterface
    associatedtype Key: Codable, LockKey
    associatedtype IDValue: Hashable
    static var schema: String { get }
    static var mappings: [String: Any] { get }
    static var settings: [String: Any] { get }
    
    var id: IDValue { get }
    var languageId: IDValue { get }
    var detailUserId: IDValue? { get set }
    
    var uniqueId: String { get }
    static func uniqueId(repositoryId: UUID, languageId: UUID) -> String
    
    @discardableResult
    static func createOrUpdate(detailWithId detailId: UUID, on req: Request) async throws -> ESUpdateDocumentResponse<String>?
    @discardableResult
    static func delete(allDetailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse
    
    
    @discardableResult
    static func deactivateLanguage(_ languageId: UUID, on req: Request) async throws -> ESBulkResponse?
    @discardableResult
    static func activateLanguage(_ languageId: UUID, on req: Request) async throws -> ESBulkResponse?
    @discardableResult
    static func updateLanguages(_ languageIds: [UUID], on req: Request) async throws -> ESBulkResponse?
    @discardableResult
    static func updateLanguage(_ languageId: UUID, on req: Request) async throws -> ESBulkResponse?
    
    @discardableResult
    static func deleteUser(_ userId: UUID, on req: Request) async throws -> ESBulkResponse?
}

extension ElasticModelInterface {
    var uniqueId: String {
        "\(self.id)_\(self.languageId)"
    }
    
    static func uniqueId(repositoryId: UUID, languageId: UUID) -> String {
        "\(repositoryId)_\(languageId)"
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
        let languageCodes = try await LanguageModel.query(on: req.db).all()
        let elementsToDelete = try languageCodes
            .map { try ESBulkOperation<Self, String>(operationType: .delete, index: Self.schema, id: Self.uniqueId(repositoryId: repositoryId, languageId: $0.requireID()), document: nil) }
        return try req.elastic.bulk(elementsToDelete)
    }
    
    @discardableResult
    static func deactivateLanguage(_ languageId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elementsToDeactivate = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$languageId == languageId)
            .all()
        
        guard !elementsToDeactivate.isEmpty else { return nil }
        let documents = try elementsToDeactivate
            .map { try ESBulkOperation<Self, String>(operationType: .delete, index: Self.schema, id: Self.uniqueId(repositoryId: $0.requireID(), languageId: languageId), document: nil) }
        return try req.elastic.bulk(documents)
    }
    
    @discardableResult
    static func activateLanguage(_ languageId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elementsToActivate = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$languageId == languageId)
            .all()
        
        guard !elementsToActivate.isEmpty else { return nil }
        let documents = try await elementsToActivate
            .concurrentMap { try await $0.toElasticsearch(on: req.db) }
            .map { ESBulkOperation(operationType: .create, index: Self.schema, id: $0.uniqueId, document: $0) }
        return try req.elastic.bulk(documents)
    }
    
    @discardableResult
    static func updateLanguages(_ languageIds: [UUID], on req: Request) async throws -> ESBulkResponse? {
        let elementsToChange = try await DatabaseModel
            .query(on: req.db)
            .filter(\._$languageId ~~ languageIds)
            .all()
        
        guard !elementsToChange.isEmpty else { return nil }
        let documents = try await elementsToChange
            .concurrentMap { try await $0.toElasticsearch(on: req.db) }
            .map { ESBulkOperation(operationType: .update, index: Self.schema, id: $0.uniqueId, document: $0) }
        return try req.elastic.bulk(documents)
    }
    
    @discardableResult
    static func updateLanguage(_ languageId: UUID, on req: Request) async throws -> ESBulkResponse? {
        try await updateLanguages([languageId], on: req)
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
                return ESBulkOperation(operationType: .update, index: Self.schema, id: document.uniqueId, document: document)
            }
        let response = try req.elastic.bulk(documents)
        return response
    }
}
