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
    
    var languageCode: String { get }
    var _$languageCode: FieldProperty<Self, String> { get }
    
    var detailId: UUID { get }
    var _$detailId: FieldProperty<Self, UUID> { get }
    
    var detailUserId: UUID? { get }
    var _$detailUserId: OptionalFieldProperty<Self, UUID> { get }
    
    
    func toElasticsearch(on db: Database) async throws -> ElasticModel
}

