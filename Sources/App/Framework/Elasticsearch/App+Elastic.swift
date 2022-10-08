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
    /// The elasticsearch client to interact with elasticsearch.
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
    
    /// The elasticsearch handler.
    var elastic: ElasticHandler {
        get throws {
            try .init(elastic: self.elasticClient)
        }
    }
}

extension Request {
    /// The elasticsearch client to interact with elasticsearch.
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
    
    /// The elasticsearch handler
    var elastic: ElasticHandler {
        get throws {
            try .init(elastic: self.elasticClient)
        }
    }
}
