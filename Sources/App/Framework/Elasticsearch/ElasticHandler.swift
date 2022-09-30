//
//  ElasticHandler.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import ElasticsearchNIOClient

public struct ElasticHandler {
    private let app: Application
    private let elastic: ElasticsearchClient
    
    init(app: Application, elastic: ElasticsearchClient) {
        self.app = app
        self.elastic = elastic
    }
    
    func createOrUpdate<Document: ElasticModelInterface>(_ document: Document) throws -> ESUpdateDocumentResponse<String> {
        try app.locks.lock(for: Document.Key.self).withLock {
            try elastic.updateDocument(document, id: document.id.uuidString, in: document.schema).wait()
        }
    }
    
    func bulk<Document: ElasticModelInterface>(_ operations: [ESBulkOperation<Document, String>]) throws -> ESBulkResponse {
        try app.locks.lock(for: Document.Key.self).withLock {
            try elastic.bulk(operations).wait()
        }
    }
    
    @discardableResult
    func createIndex(_ indexName: String, mappings: [String: Any], settings: [String: Any]) async throws -> ESDeleteIndexResponse {
        try await elastic.createIndex(indexName, mappings: mappings, settings: settings).get()
    }
    
    @discardableResult
    func deleteIndex(_ indexName: String) async throws -> ESDeleteIndexResponse {
        try await elastic.deleteIndex(indexName).get()
    }
    
    func get<Document: Decodable, ID: Hashable>(document documentType: Document.Type = Document.self, id: ID, from indexName: String) async throws -> ESGetSingleDocumentResponse<Document> {
        try await elastic.get(id: id, from: indexName).get()
    }
    
    func searchDocumentsCount(from indexName: String, searchTerm: String?) async throws -> ESCountResponse {
        try await elastic.searchDocumentsCount(from: indexName, searchTerm: searchTerm).get()
    }
    
    func customSearch<Document: Decodable, Query: Encodable>(index indexName: String, query: Query, type: Document.Type = Document.self) async throws -> ESGetMultipleDocumentsResponse<Document> {
        try await elastic.customSearch(from: indexName, query: query, type: type).get()
    }
    
    func custom(_ path: String, method: HTTPMethod, body: Data) async throws -> Data {
        try await elastic.custom(path, method: method, body: body).get()
    }
}
