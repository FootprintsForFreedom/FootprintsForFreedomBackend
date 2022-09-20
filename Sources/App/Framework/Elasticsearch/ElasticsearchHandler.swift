//
//  ElasticsearchHandler.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import ElasticsearchNIOClient

struct ElasticsearchHandler {
    static func newJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)

            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateStr) {
                return date
            }
            throw DecodingError.typeMismatch(Date.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not decode date"))
        })
        return decoder
    }
    
    static func newJSONEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        encoder.dateEncodingStrategy = .formatted(formatter)
        return encoder
    }
    
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
    
    @discardableResult
    func createIndex(_ indexName: String, mappings: [String: Any], settings: [String: Any]) async throws -> ESDeleteIndexResponse {
        let response = try await elastic.createIndex(indexName, mappings: mappings, settings: settings).get()
        print(response)
        return response
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
}
