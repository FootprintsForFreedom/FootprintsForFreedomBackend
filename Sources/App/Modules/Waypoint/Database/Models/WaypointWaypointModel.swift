//
//  WaypointWaypointModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class WaypointWaypointModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var title: FieldKey { "title" }
            static var description: FieldKey { "description" }
            static var languageId: FieldKey { "language_id" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Field(key: FieldKeys.v1.title) var title: String
    @Field(key: FieldKeys.v1.description) var description: String
    
    // TODO: likes as sibling?
    
    @Parent(key: FieldKeys.v1.languageId) var language: LanguageModel
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        verified: Bool = false,
        title: String,
        description: String,
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.verified = verified
        self.title = title
        self.description = description
        self.$language.id = languageId
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension WaypointWaypointModel: Equatable {
    static func == (lhs: WaypointWaypointModel, rhs: WaypointWaypointModel) -> Bool {
        lhs.id == rhs.id
    }
}
