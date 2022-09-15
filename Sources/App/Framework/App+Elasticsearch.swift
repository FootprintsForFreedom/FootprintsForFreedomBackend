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
    var elastic: ElasticsearchClient {
        get throws {
            try ElasticsearchClient(
                httpClient: self.http.client.shared,
                eventLoop: self.eventLoopGroup.next(),
                logger: self.logger,
                url: Environment.elasticsearchUrl
            )
        }
    }
}

extension Request {
    var elastic: ElasticsearchClient {
        get throws {
            try ElasticsearchClient(
                httpClient: application.http.client.shared,
                eventLoop: eventLoop,
                logger: logger,
                url: Environment.elasticsearchUrl
            )
        }
    }
}
