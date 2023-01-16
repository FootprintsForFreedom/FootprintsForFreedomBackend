//
//  MediaSummaryModel.swift
//  
//
//  Created by niklhut on 09.01.23.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

final class MediaSummaryModel: DatabaseElasticInterface {
    typealias Module = MediaModule
    
    static var schema: String = "media_summaries"
    
    struct FieldKeys {
        struct v1 {
            // MediaDetail
            static var waypointId: FieldKey { "waypoint_id" }
            static var title: FieldKey { "title" }
            static var slug: FieldKey { "slug" }
            static var detailText: FieldKey { "detail_text" }
            static var source: FieldKey { "source" }
            static var repositoryId: FieldKey { "repository_id" }
            static var mediaId: FieldKey { "media_id" }
            static var detailUserId: FieldKey { "detail_user_id" }
            static var detailVerifiedAt: FieldKey { "detail_verified_at" }
            static var detailCreatedAt: FieldKey { "detail_created_at" }
            static var detailUpdatedAt: FieldKey { "detail_updated_at" }
            static var detailDeletedAt: FieldKey { "detail_deleted_at" }
            static var detailId: FieldKey { "detail_id" }
            // MediaFile
            static var fileId: FieldKey { "file_id" }
            static var mediaDirectory: FieldKey { "media_directory" }
            static var group: FieldKey { "group" }
            static var fileUserId: FieldKey { "file_user_id" }
            static var fileCreatedAt: FieldKey { "file_created_at" }
            static var fileUpdatedAt: FieldKey { "file_updated_at" }
            static var fileDeletedAt: FieldKey { "file_deleted_at" }
            // Language
            static var languageCode: FieldKey { "language_code" }
            static var languageName: FieldKey { "language_name" }
            static var languageIsRTL: FieldKey { "language_is_rtl" }
            static var languagePriority: FieldKey { "language_priority" }
            static var languageId: FieldKey { "language_id" }
        }
    }
    
    @ID() var id: UUID?
    
    @Field(key: FieldKeys.v1.waypointId) var waypointId: UUID
    @Field(key: FieldKeys.v1.detailId) var detailId: UUID
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.slug) var slug: String
    @Field(key: FieldKeys.v1.detailText) var detailText: String
    @Field(key: FieldKeys.v1.source) var source: String
    @OptionalField(key: FieldKeys.v1.detailUserId) var detailUserId: UUID?
    @OptionalField(key: FieldKeys.v1.detailVerifiedAt) var detailVerifiedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailCreatedAt) var detailCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailUpdatedAt) var detailUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.detailDeletedAt) var detailDeletedAt: Date?
    
    @Field(key: FieldKeys.v1.fileId) var fileId: UUID
    @Field(key: FieldKeys.v1.mediaDirectory) var relativeMediaFilePath: String
    @Enum(key: FieldKeys.v1.group) var group: Media.Detail.Group
    @OptionalField(key: FieldKeys.v1.fileUserId) var fileUserId: UUID?
    @OptionalField(key: FieldKeys.v1.fileCreatedAt) var fileCreatedAt: Date?
    @OptionalField(key: FieldKeys.v1.fileUpdatedAt) var fileUpdatedAt: Date?
    @OptionalField(key: FieldKeys.v1.fileDeletedAt) var fileDeletedAt: Date?
    
    @Field(key: FieldKeys.v1.languageId) var languageId: UUID
    @Field(key: FieldKeys.v1.languageName) var languageName: String
    @Field(key: FieldKeys.v1.languageCode) var languageCode: String
    @Field(key: FieldKeys.v1.languageIsRTL) var languageIsRTL: Bool
    @OptionalField(key: FieldKeys.v1.languagePriority) var languagePriority: Int?
    
    init() { }
}

extension MediaSummaryModel {
    var _$languageCode: FieldProperty<MediaSummaryModel, String> { $languageCode }
    var _$detailId: FieldProperty<MediaSummaryModel, UUID> { $detailId }
    var _$detailUserId: OptionalFieldProperty<MediaSummaryModel, UUID> { $detailUserId }
}

extension MediaSummaryModel {
    struct Elasticsearch: ElasticModelInterface {
        typealias DatabaseModel = MediaSummaryModel
        
        static var baseSchema = "media"
        static var mappings: [String : Any] = [
            "properties": [
                "title": [
                    "type": "text",
                    "fields": [
                        "keyword": [
                            "type": "keyword"
                        ],
                        "suggest": [
                            "type": "completion",
                            "analyzer": "default"
                        ]
                    ]
                ],
                "slug": [
                    "type": "keyword"
                ],
                "id": [
                    "type": "keyword"
                ],
                "waypointId": [
                    "type": "keyword"
                ],
                "detailId": [
                    "type": "keyword"
                ],
                "detailUserId": [
                    "type": "keyword"
                ],
                "fileId": [
                    "type": "keyword"
                ],
                "fileUserId": [
                    "type": "keyword"
                ],
                "languageId": [
                    "type": "keyword"
                ],
                "languageIsRTL": [
                    "type": "boolean"
                ],
                "languageCode": [
                    "type": "keyword"
                ],
                "tags": [
                    "type": "keyword"
                ]
            ]
        ]
        
        var id: UUID
        var waypointId: UUID
        
        var detailId: UUID
        var title: String
        var slug: String
        var detailText: String
        var source: String
        @NullCodable var detailUserId: UUID?
        var detailVerifiedAt: Date?
        var detailCreatedAt: Date?
        var detailUpdatedAt: Date?
        var detailDeletedAt: Date?
        
        var fileId: UUID
        var relativeMediaFilePath: String
        var group: Media.Detail.Group
        @NullCodable var fileUserId: UUID?
        var fileCreatedAt: Date?
        var fileUpdatedAt: Date?
        var fileDeletedAt: Date?
        
        var languageId: UUID
        var languageName: String
        var languageCode: String
        var languageIsRTL: Bool
        var languagePriority: Int?
        
        var tags: [UUID]
    }
    
    func toElasticsearch(on db: Database) async throws -> Elasticsearch {
        let tags = try await MediaTagModel
            .query(on: db)
            .filter(\.$media.$id == self.requireID())
            .field(\.$tag.$id)
            .all()
            .map { $0.$tag.id }
        return try self.toElasticsearch(tags: tags)
    }
    
    func toElasticsearch(tags: [UUID]) throws -> Elasticsearch {
        try Elasticsearch(
            id: self.requireID(),
            waypointId: self.waypointId,
            detailId: self.detailId,
            title: self.title,
            slug: self.slug,
            detailText: self.detailText,
            source: self.source,
            detailUserId: self.detailUserId,
            detailVerifiedAt: self.detailVerifiedAt,
            detailCreatedAt: self.detailCreatedAt,
            detailUpdatedAt: self.detailUpdatedAt,
            detailDeletedAt: self.detailDeletedAt,
            fileId: self.fileId,
            relativeMediaFilePath: self.relativeMediaFilePath,
            group: self.group,
            fileUserId: self.fileUserId,
            fileCreatedAt: self.fileCreatedAt,
            fileUpdatedAt: self.fileUpdatedAt,
            fileDeletedAt: self.fileDeletedAt,
            languageId: self.languageId,
            languageName: self.languageName,
            languageCode: self.languageCode,
            languageIsRTL: self.languageIsRTL,
            languagePriority: self.languagePriority,
            tags: tags
        )
    }
}

extension MediaSummaryModel.Elasticsearch {
    @discardableResult
    static func createOrUpdate(detailsWithRepositoryId repositoryId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elements = try await DatabaseModel
            .query(on: req.db)
            .filter(\.$id == repositoryId)
            .all()
        guard !elements.isEmpty else { return nil }
        let documents = try await elements
            .concurrentMap { try await $0.toElasticsearch(on: req.db) }
            .map { ESBulkOperation(operationType: .index, index: $0.schema, id: $0.id, document: $0) }
        let response = try await req.elastic.bulk(documents)
        return response
    }
    
    @discardableResult
    static func deleteUser(_ userId: UUID, on req: Request) async throws -> ESBulkResponse? {
        let elementsToDelete = try await DatabaseModel
            .query(on: req.db)
            .group(.or) { query in
                query
                    .filter(\.$detailUserId == userId)
                    .filter(\.$fileUserId == userId)
            }
            .all()
        
        guard !elementsToDelete.isEmpty else { return nil }
        let documents = try await elementsToDelete
            .concurrentMap { element in
                var document = try await element.toElasticsearch(on: req.db)
                if document.detailUserId == userId {
                    document.detailUserId = nil
                }
                if document.fileUserId == userId {
                    document.fileUserId = nil
                }
                return document
            }
            .map { (document: Self) in
                return ESBulkOperation(operationType: .update, index: document.schema, id: document.id, document: document)
            }
        let response = try await req.elastic.bulk(documents)
        return response
    }
    
    func getTagList(preferredLanguageCode: String?, on elastic: ElasticHandler) async throws -> [Tag.Detail.List] {
        if !self.tags.isEmpty {
            var query: [String: Any] = [
                "query": [
                    "terms": [
                        "id": self.tags
                    ]
                ],
                "collapse": [
                    "field": "id"
                ],
            ]
            var sort: [[String: Any]] = []
            if let preferredLanguageCode = preferredLanguageCode {
                sort.append(
                    [
                        "_script": [
                            "type": "number",
                            "script": [
                                "lang": "painless",
                                "source": "doc['languageCode'].value == params.preferredLanguageCode ? 0 : doc['languagePriority'].value",
                                "params": [
                                    "preferredLanguageCode": "\(preferredLanguageCode)"
                                ]
                            ],
                            "order": "asc"
                        ]
                    ]
                )
            } else {
                sort.append(["languagePriority": "asc"])
            }
            sort.append([ "title.keyword": "asc" ])
            query["sort"] = sort
            
            return try await elastic.perform {
                guard
                    let queryData = try? JSONSerialization.data(withJSONObject: query),
                    let responseData = try? await elastic.custom("/\(LatestVerifiedTagModel.Elasticsearch.baseSchema)/_search", method: .GET, body: queryData),
                    let response = try? ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<LatestVerifiedTagModel.Elasticsearch>.self, from: responseData)
                else {
                    throw Abort(.internalServerError)
                }
                
                return response.hits.hits.map {
                    let source = $0.source
                    return .init(
                        id: source.id,
                        title: source.title,
                        slug: source.slug
                    )
                }
            }
        } else {
            return []
        }
    }
}
