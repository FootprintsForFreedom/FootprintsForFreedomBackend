//
//  WaypointLocationModel.swift
//  
//
//  Created by niklhut on 19.03.22.
//

import Vapor
import Fluent

final class WaypointLocationModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var latitude: FieldKey { "latitude" }
            static var longitude: FieldKey { "longitude" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Field(key: FieldKeys.v1.latitude) var latitude: Double
    @Field(key: FieldKeys.v1.longitude) var longitude: Double
    
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
        latitude: Double,
        longitude: Double,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.verified = verified
        self.latitude = latitude
        self.longitude = longitude
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}
