//
//  ElasticHandler.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import ElasticsearchNIOClient

/// Steamlines handling elasticsearch requests.
public struct ElasticHandler {
    /// The elasticsearch client to handle the requests
    private let elastic: ElasticsearchClient
    
    init(elastic: ElasticsearchClient) {
        self.elastic = elastic
    }
    
    /// Create or update an elastic model interface.
    /// - Parameter document: The elastic model to create or update.
    /// - Returns: The document response.
    func createOrUpdate<Document: ElasticModelInterface>(_ document: Document) async throws -> ESUpdateDocumentResponse<Document.ID> {
        try await elastic.updateDocument(document, in: document.schema).get()
    }
    
    /// Performs a bulk operation.
    /// - Parameter operations: The single operations to perform.
    /// - Returns: An elasticsearch bulk response.
    func bulk<Document: ElasticModelInterface, ID: Hashable>(_ operations: [ESBulkOperation<Document, ID>]) async throws -> ESBulkResponse {
        try await elastic.bulk(operations).get()
    }
    
    /// Creates an index.
    /// - Parameters:
    ///   - indexName: The name of the index to create.
    ///   - mappings: The mappings to be used for this index.
    ///   - settings: The settings to be used for this index.
    /// - Returns: Wether or not the request was acknowledged.
    @discardableResult
    func createIndex(_ indexName: String, mappings: [String: Any], settings: [String: Any]) async throws -> ESAcknowledgedResponse {
        try await elastic.createIndex(indexName, mappings: mappings, settings: settings).get()
    }
    
    /// Deletes an index in all available languages.
    ///
    /// This acts like an wildcard delete for an index since those are not enabled in elasticsearch.
    /// - Parameters:
    ///   - indexType: The index type to delete for all languages.
    ///   - languages: The languages for which to delete the index.
    /// - Returns: An array of acknowledged responses.
    @discardableResult
    func deleteIndex(_ indexType: any ElasticModelInterface.Type, for languages: [LanguageModel]) async throws -> [ESAcknowledgedResponse] {
        try await languages.asyncMap { language in
            try await deleteIndex(indexType.schema(for: language.languageCode))
        }
    }
    
    /// Deletes an index.
    /// - Parameter indexName: The name of the index to delete.
    /// - Returns: Wether or not the request was acknowledged.
    @discardableResult
    func deleteIndex(_ indexName: String) async throws -> ESAcknowledgedResponse {
        try await elastic.deleteIndex(indexName).get()
    }
    
    /// Gets an elastic model by its id.
    /// - Parameters:
    ///   - documentType: The type of the document.
    ///   - id: The id of the model to get.
    ///   - indexName: The index on which to get the document.
    /// - Returns: The document as single document response.
    func get<Document: Decodable, ID: Hashable>(document documentType: Document.Type = Document.self, id: ID, from indexName: String) async throws -> ESGetSingleDocumentResponse<Document> {
        try await elastic.get(id: id, from: indexName).get()
    }
    
    /// Performs a custom request.
    /// - Parameters:
    ///   - path: The path on which to perform the elasticsearch request.
    ///   - method: The method for of request.
    ///   - body: The body of the request.
    /// - Returns: The returned data.
    func custom(_ path: String, method: HTTPMethod, body: Data) async throws -> Data {
        try await elastic.custom(path, method: method, body: body).get()
    }
    
    /// Performs an elasticsearch request and handles any thrown error appropriately.
    /// - Parameter request: The request to perform.
    /// - Returns: The result of the request if no error was thrown.
    func perform<ReturnType>(_ request: () async throws -> ReturnType) async rethrows -> ReturnType {
        do {
            return try await request()
        } catch let error as ElasticSearchClientError {
            guard let status = error.status else { throw Abort(.internalServerError) }
            throw Abort(status)
        } catch let error as Abort {
            throw error
        } catch {
            throw Abort(.internalServerError)
        }
    }
}
