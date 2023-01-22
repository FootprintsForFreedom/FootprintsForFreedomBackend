//
//  RedirectModel.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Vapor
import Fluent

final class RedirectModel: DatabaseModelInterface {
    typealias Module = RedirectModule
    
    static let schema = "redirects"
    
    struct FieldKeys {
        struct v1 {
            static var source: FieldKey { "source" }
            static var destination: FieldKey { "destination" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.source) var source: String
    @Field(key: FieldKeys.v1.destination) var destination: String
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        source: String,
        destination: String
    ) {
        self.id = id
        self.source = source
        self.destination = destination
    }
}
