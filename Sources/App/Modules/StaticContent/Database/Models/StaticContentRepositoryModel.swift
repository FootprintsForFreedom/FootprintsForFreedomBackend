//
//  StaticContentModel.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor
import Fluent

final class StaticContentRepositoryModel: RepositoryModel {
    typealias Module = StaticContentModule
    
    static var identifier = "repositories"
    
    struct FieldKeys {
        struct v1 {
            static var slug: FieldKey { "slug" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.slug) var slug: String
    
    @Children(for: \.$repository) var details: [StaticContentDetailModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(slug: String) {
        self.slug = slug
    }
}

extension StaticContentRepositoryModel {
    var _$details: ChildrenProperty<StaticContentRepositoryModel, StaticContentDetailModel> { $details }
}
