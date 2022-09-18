//
//  LatestVerifiedTagModel.swift
//  
//
//  Created by niklhut on 15.09.22.
//

import Vapor
import Fluent

final class LatestVerifiedTagModel: DatabaseElasticsearchInterface {
    typealias Module = TagModule
    
    static var schema: String = "latest_verified_tag_details"
    
    struct FieldKeys {
        struct v1 {
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var keywords: FieldKey { "keywords" }
            static var detailUserId: FieldKey { "detail_user_id" }
            static var detailVerifiedAt: FieldKey { "detail_verified_at" }
            static var detailCreatedAt: FieldKey { "detail_created_at" }
            static var detailUpdatedAt: FieldKey { "detail_updated_at" }
            static var detailDeletedAt: FieldKey { "detail_deleted_at" }
            static var detailId: FieldKey { "detail_id" }
            static var languageCode: FieldKey { "language_code" }
            static var languageName: FieldKey { "language_name" }
            static var languageIsRTL: FieldKey { "language_is_rtl" }
            static var languagePriority: FieldKey { "language_priority" }
            static var languageId: FieldKey { "language_id" }
        }
    }
    
    @ID() var id: UUID?
    
    @Field(key: FieldKeys.v1.detailId) var detailId: UUID
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.keywords) var keywords: [String]
    @OptionalField(key: FieldKeys.v1.detailUserId) var detailUserId: UUID?
    @OptionalField(key: FieldKeys.v1.detailVerifiedAt) var detailVerifiedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailCreatedAt) var detailCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailUpdatedAt) var detailUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailDeletedAt) var detailDeletedAt: Date?
    
    @Field(key: FieldKeys.v1.languageId) var languageId: UUID
    @Field(key: FieldKeys.v1.languageName) var languageName: String
    @Field(key: FieldKeys.v1.languageCode) var languageCode: String
    @Field(key: FieldKeys.v1.languageIsRTL) var languageIsRTL: Bool
    @OptionalField(key: FieldKeys.v1.languagePriority) var languagePriority: Int?
    
    init() { }
}

extension LatestVerifiedTagModel {
    var _$languageId: FieldProperty<LatestVerifiedTagModel, UUID> { $languageId }
    var _$detailId: FieldProperty<LatestVerifiedTagModel, UUID> { $detailId }
}

extension LatestVerifiedTagModel {
    struct Elasticsearch: ElasticsearchModelInterface {
        typealias DatabaseModel = LatestVerifiedTagModel
        struct Key: Codable, LockKey { }
        
        static var schema = "tags"
        
        var id: UUID
        
        var detailId: UUID
        var title: String
        var slug: String
        var keywords: [String]
        var detailUserId: UUID?
        var detailVerifiedAt: Date?
        var detailCreatedAt: Date?
        var detailUpdatedAt: Date?
        var detailDeletedAt: Date?
        
        var languageId: UUID
        var languageName: String
        var languageCode: String
        var languageIsRTL: Bool
        var languagePriority: Int?
    }
    
    func toElasticsearch(on db: Database) async throws -> Elasticsearch {
        try self.toElasticsearch()
    }
    
    func toElasticsearch() throws -> Elasticsearch {
        try Elasticsearch(
            id: self.requireID(),
            detailId: self.detailId,
            title: self.title,
            slug: self.slug,
            keywords: self.keywords,
            detailUserId: self.detailUserId,
            detailVerifiedAt: self.detailVerifiedAt,
            detailCreatedAt: self.detailCreatedAt,
            detailUpdatedAt: self.detailUpdatedAt,
            detailDeletedAt: self.detailDeletedAt,
            languageId: self.languageId,
            languageName: self.languageName,
            languageCode: self.languageCode,
            languageIsRTL: self.languageIsRTL,
            languagePriority: self.languagePriority
        )
    }
}
