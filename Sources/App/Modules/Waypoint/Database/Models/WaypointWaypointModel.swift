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
            static var locationId: FieldKey { "location_id" }
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
    
    @Children(for: \.$waypoint) var media: [WaypointMediaModel]
    
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

//extension WaypointWaypointModel {
//    func set<T>(_ keyPath: KeyPath<WaypointWaypointModel, ParentProperty<WaypointWaypointModel, StorableObjectModel<T>>>, to newValue: T, _ userId: UUID, on db: Database) async throws {
//        let newObject = StorableObjectModel<T>(value: newValue, userId: userId)
//        try await newObject.create(on: db)
//        let property = self[keyPath: keyPath]
//        property.id = try newObject.requireID()
//    }
//
//    func with(
//        title: String,
//        description: String,
//        location: Waypoint.Location,
//        repositoryId: UUID,
//        languageId: UUID,
//        userId: UUID,
//        verified: Bool,
//        on db: Database
//    ) async throws {
//        try await self.set(\.$title, to: title, userId, on: db)
//        try await self.set(\.$description, to: description, userId, on: db)
//        try await self.set(\.$location, to: location, userId, on: db)
//        self.$repository.id = repositoryId
//        self.$language.id = languageId
//        self.$user.id = userId
//        self.verified = verified
//    }
//
//    static func createWith(
//        title: String,
//        description: String,
//        location: Waypoint.Location,
//        repositoryId: UUID,
//        languageId: UUID,
//        userId: UUID,
//        verified: Bool,
//        on db: Database
//    ) async throws -> Self {
//        let title = StorableObjectModel<String>(value: title, userId: userId)
//        try await title.create(on: db)
//        let description = StorableObjectModel<String>(value: description, userId: userId)
//        try await description.create(on: db)
//        let location = StorableObjectModel<Waypoint.Location>(value: location, userId: userId)
//        try await location.create(on: db)
//
//        let waypoint = try self.init(
//            verified: verified,
//            titleId: title.requireID(),
//            descriptionId: description.requireID(),
//            locationId: location.requireID(),
//            languageId: languageId,
//            repositoryId: repositoryId,
//            userId: userId
//        )
//        try await waypoint.create(on: db)
//        return waypoint
//    }
//}
//
//extension WaypointWaypointModel {
//    func load(on db: Database) async throws {
//        try await self.$title.load(on: db)
//        try await self.$description.load(on: db)
//        try await self.$location.load(on: db)
//        try await self.$language.load(on: db)
//        try await self.$user.load(on: db)
//    }
//}
