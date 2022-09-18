//
//  DatabaseElasticsearchInterface.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import Fluent

protocol DatabaseElasticsearchInterface: DatabaseModelInterface {
    associatedtype Elasticsearch: ElasticsearchModelInterface
    
    var languageId: UUID { get }
    var _$languageId: FieldProperty<Self, UUID> { get }
    
    var detailId: UUID { get }
    var _$detailId: FieldProperty<Self, UUID> { get }
    
    
    func toElasticsearch(on db: Database) async throws -> Elasticsearch
}

