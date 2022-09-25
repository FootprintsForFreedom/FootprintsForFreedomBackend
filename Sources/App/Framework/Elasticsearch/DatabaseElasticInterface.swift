//
//  DatabaseElasticInterface.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import Fluent

protocol DatabaseElasticInterface: DatabaseModelInterface {
    associatedtype ElasticModel: ElasticModelInterface
    
    var languageId: UUID { get }
    var _$languageId: FieldProperty<Self, UUID> { get }
    
    var detailId: UUID { get }
    var _$detailId: FieldProperty<Self, UUID> { get }
    
    var detailUserId: UUID? { get }
    var _$detailUserId: OptionalFieldProperty<Self, UUID> { get }
    
    
    func toElasticsearch(on db: Database) async throws -> ElasticModel
}

