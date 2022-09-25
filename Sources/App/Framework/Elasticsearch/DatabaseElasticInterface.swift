//
//  DatabaseElasticInterface.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import Fluent

public protocol DatabaseElasticInterface: DatabaseModelInterface {
    associatedtype ElasticModel: ElasticModelInterface
    
    var languageId: UUID { get }
    var _$languageId: FieldProperty<Self, UUID> { get }
    
    var detailId: UUID { get }
    var _$detailId: FieldProperty<Self, UUID> { get }
    
    
    func toElasticsearch(on db: Database) async throws -> ElasticModel
}

