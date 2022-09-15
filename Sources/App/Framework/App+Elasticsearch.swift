//
//  App+Elasticsearch.swift
//  
//
//  Created by niklhut on 12.09.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

extension Application {
    // TODO: make configurable in configure.swift?
    private var elasticClient: ElasticsearchClient {
        get throws {
            try ElasticsearchClient(
                httpClient: self.http.client.shared,
                eventLoop: self.eventLoopGroup.next(),
                logger: self.logger,
                url: Environment.elasticsearchUrl
            )
        }
    }
    
    var elastic: ElasticsearchHandler {
        get throws {
            try .init(app: self, elastic: self.elasticClient)
        }
    }
}

extension Request {
    private var elasticClient: ElasticsearchClient {
        get throws {
            try ElasticsearchClient(
                httpClient: application.http.client.shared,
                eventLoop: eventLoop,
                logger: logger,
                url: Environment.elasticsearchUrl
            )
        }
    }
    
    var elastic: ElasticsearchHandler {
        get throws {
            try .init(app: self.application, elastic: self.elasticClient)
        }
    }
}

struct ElasticsearchHandler {
    let app: Application
    let elastic: ElasticsearchClient
    
    func createOrUpdate<Document: Encodable & LockKey, ID: Hashable>(_ document: Document, id: ID, in indexName: String) throws -> ESUpdateDocumentResponse<ID> {
        try app.locks.lock(for: Document.self).withLock {
            try elastic.updateDocument(document, id: id, in: indexName).wait()
        }
    }
    
    func bulk<Document: Encodable & LockKey, ID: Hashable>(_ operations: [ESBulkOperation<Document, ID>]) throws -> ESBulkResponse {
        try app.locks.lock(for: Document.self).withLock {
            try elastic.bulk(operations).wait()
        }
    }
}
