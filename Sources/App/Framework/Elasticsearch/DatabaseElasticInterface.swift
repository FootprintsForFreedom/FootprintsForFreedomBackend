//
//  DatabaseElasticInterface.swift
//  
//
//  Created by niklhut on 18.09.22.
//

import Vapor
import Fluent

/// Interface between elastichsearch and the database
public protocol DatabaseElasticInterface: DatabaseModelInterface {
    /// The associated elastic model interface.
    associatedtype ElasticModel: ElasticModelInterface
    
    /// The model's language code.
    var languageCode: String { get }
    /// The model's language code.
    var _$languageCode: FieldProperty<Self, String> { get }
    
    /// The model's detail id.
    var detailId: UUID { get }
    /// The model's detail id.
    var _$detailId: FieldProperty<Self, UUID> { get }
    
    /// The model's detail user id.
    var detailUserId: UUID? { get }
    /// The model's detail user id.
    var _$detailUserId: OptionalFieldProperty<Self, UUID> { get }
    
    
    /// Converts the database model to its associated elastic model.
    /// - Parameter db: The database on which to convert the model.
    /// - Returns: The corresponding elastic model.
    func toElasticsearch(on db: Database) async throws -> ElasticModel
}
