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
            static var requiredSnippets: FieldKey { "required_snippets" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.requiredSnippets) var requiredSnippets: [StaticContent.Snippet]
    
    @Children(for: \.$repository) var details: [StaticContentDetailModel]
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(slug: String, requiredSnippets: [StaticContent.Snippet] = []) {
        self.slug = slug
        self.requiredSnippets = requiredSnippets
    }
}

extension StaticContentRepositoryModel {
    static var ownKeyPathOnDetail: KeyPath<StaticContentDetailModel, ParentProperty<StaticContentDetailModel, StaticContentRepositoryModel>> { \.$repository }
    var _$details: ChildrenProperty<StaticContentRepositoryModel, StaticContentDetailModel> { $details }
    var _$updatedAt: TimestampProperty<StaticContentRepositoryModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<StaticContentRepositoryModel, DefaultTimestampFormat> { $deletedAt }
}
