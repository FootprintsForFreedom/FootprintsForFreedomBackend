//
//  ElasticsearchHandler.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import ElasticsearchNIOClient

struct ElasticsearchHandler {
    private let app: Application
    private let elastic: ElasticsearchClient
    
    init(app: Application, elastic: ElasticsearchClient) {
        self.app = app
        self.elastic = elastic
    }
    
    func createOrUpdate<Document: ElasticsearchModelInterface>(_ document: Document) throws -> ESUpdateDocumentResponse<String> {
        try app.locks.lock(for: Document.Key.self).withLock {
            try elastic.updateDocument(document, id: document.uniqueId, in: Document.schema).wait()
        }
    }
    
    func bulk<Document: ElasticsearchModelInterface>(_ operations: [ESBulkOperation<Document, String>]) throws -> ESBulkResponse {
        try app.locks.lock(for: Document.Key.self).withLock {
            try elastic.bulk(operations).wait()
        }
    }
    
    public func get<Document: Decodable, ID: Hashable>(document documentType: Document.Type = Document.self, id: ID, from indexName: String) async throws -> ESGetSingleDocumentResponse<Document> {
        try await elastic.get(id: id, from: indexName).get()
    }
    
    func searchDocumentsCount(from indexName: String, searchTerm: String?) async throws -> ESCountResponse {
        try await elastic.searchDocumentsCount(from: indexName, searchTerm: searchTerm).get()
    }
}
