//
//  App+Elastic.swift
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
                url: Environment.elasticsearchUrl,
                jsonEncoder: ElasticHandler.newJSONEncoder(),
                jsonDecoder: ElasticHandler.newJSONDecoder()
            )
        }
    }
    
    var elastic: ElasticHandler {
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
                url: Environment.elasticsearchUrl,
                jsonEncoder: ElasticHandler.newJSONEncoder(),
                jsonDecoder: ElasticHandler.newJSONDecoder()
            )
        }
    }
    
    var elastic: ElasticHandler {
        get throws {
            try .init(app: self.application, elastic: self.elasticClient)
        }
    }
}
