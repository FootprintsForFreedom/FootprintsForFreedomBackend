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

/// Iterface between elasticsearch and a model.
public protocol ElasticModelInterface: Codable where DatabaseModel.ElasticModel == Self {
    /// The associated database model.
    associatedtype DatabaseModel: DatabaseElasticInterface
    /// The associated id value.
    associatedtype IDValue: Hashable
    
    /// The base schema for this model.
    static var baseSchema: String { get }
    
    /// The mappings for this model.
    static var mappings: [String: Any] { get }
    
    /// The model's id.
    var id: UUID { get }
    
    /// The model's language code.
    var languageCode: String { get }
    
    /// The model's detail user id.
    var detailUserId: IDValue? { get set }
    
    /// The model's schema.
    var schema: String { get }
    
    /// The schema for all models regardless of language.
    static var wildcardSchema: String { get }
    
    /// Gets the schema for this model in a certain language.
    /// - Parameter languageCode: The language code of the language for the schema.
    /// - Returns: The schema for the model in the specified language.
    static func schema(for languageCode: String) -> String
    
    /// Create or update a model.
    /// - Parameters:
    ///   - detailId: The detail id of the model.
    ///   - req: The request on which to create or update the model.
    /// - Returns: The document response
    @discardableResult
    static func createOrUpdate(detailWithId detailId: UUID, on req: Request) async throws -> ESUpdateDocumentResponse<String>?
    
    /// Deletes all models with a repository id from elasticsearch.
    /// - Parameters:
    ///   - repositoryId: The repository id for which to delete all models.
    ///   - req: The request on which to delete the models.
    /// - Returns: An elasticsearch bulk response.
    @discardableResult
    static func delete(allDetailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse
    
    /// Creates an index for the model in a specified language.
    /// - Parameters:
    ///   - languageCode: The language code of the language for the new index.
    ///   - elastic: The elastic handler on which to create the index.
    /// - Returns: Wether or not the request was acknowledged.
    @discardableResult
    static func createIndex(for languageCode: String, on elastic: ElasticHandler) async throws -> ESDeleteIndexResponse
    
    /// Deactivates a language.
    /// - Parameters:
    ///   - languageCode: The language code of the language to deactivate.
    ///   - elastic: The elastic handler on which to deactivate the language.
    /// - Returns:Wether or not the request was acknowledged.
    @discardableResult
    static func deactivateLanguage(_ languageCode: String, on elastic: ElasticHandler) async throws -> ESDeleteIndexResponse
    
    /// Activates a language.
    /// - Parameters:
    ///   - languageCode: The language code of the language to activate.
    ///   - req: The request on which to activate the language.
    /// - Returns: An elasticsearch bulk response.
    @discardableResult
    static func activateLanguage(_ languageCode: String, on req: Request) async throws -> ESBulkResponse?
    
    /// Updates all models of certain  languages to reflect the changes to the languages.
    /// - Parameters:
    ///   - languageCodes: The language codes of the languages to update.
    ///   - req: The request on which to update the languages.
    /// - Returns: An elasticsearch bulk response.
    @discardableResult
    static func updateLanguages(_ languageCodes: [String], on req: Request) async throws -> ESBulkResponse?
    
    /// Removes a user form all its models.
    /// - Parameters:
    ///   - userId: The id of the user to remove.
    ///   - req: The request on which to remove the user.
    /// - Returns: An elasticsearch bulk response.
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
        let response = try await req.elastic.createOrUpdate(document)
        return response
    }
    
    @discardableResult
    static func delete(allDetailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse {
        let languages = try await LanguageModel.query(on: req.db).all()
        let elementsToDelete = languages
            .map { ESBulkOperation<Self, String>(operationType: .delete, index: Self.schema(for: $0.languageCode), id: repositoryId.uuidString, document: nil) }
        return try await req.elastic.bulk(elementsToDelete)
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
        return try await req.elastic.bulk(documents)
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
        return try await req.elastic.bulk(documents)
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
        let response = try await req.elastic.bulk(documents)
        return response
    }
}
