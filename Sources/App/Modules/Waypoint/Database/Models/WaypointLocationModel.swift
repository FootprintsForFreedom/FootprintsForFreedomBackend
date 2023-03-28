//
//  WaypointLocationModel.swift
//  
//
//  Created by niklhut on 19.03.22.
//

import Vapor
import Fluent
import AppApi

final class WaypointLocationModel: DetailModel {
    typealias Module = WaypointModule
    
    struct FieldKeys {
        struct v1 {
            static var latitude: FieldKey { "latitude" }
            static var longitude: FieldKey { "longitude" }
            static var repositoryId: FieldKey { "repository_id" }
            static var userId: FieldKey { "user_id" }
            static var verifiedAt: FieldKey { "verified_at" }
            static var createdAt: FieldKey { "created_at" }
            static var updatedAt: FieldKey { "updated_at" }
            static var deletedAt: FieldKey { "deleted_at" }
        }
    }
    
    
    @ID() var id: UUID?
    
    @Field(key: FieldKeys.v1.latitude) var latitude: Double
    @Field(key: FieldKeys.v1.longitude) var longitude: Double
    
    @Parent(key: FieldKeys.v1.repositoryId) var repository: WaypointRepositoryModel
    @OptionalParent(key: FieldKeys.v1.userId) var user: UserAccountModel?
    
    @OptionalField(key: FieldKeys.v1.verifiedAt) var verifiedAt: Date?
    
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: FieldKeys.v1.updatedAt, on: .update) var updatedAt: Date?
    
    // MARK: soft delete
    @Timestamp(key: FieldKeys.v1.deletedAt, on: .delete) var deletedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        verifiedAt: Date? = nil,
        latitude: Double,
        longitude: Double,
        repositoryId: UUID,
        userId: UUID
    ) {
        self.id = id
        self.verifiedAt = verifiedAt
        self.latitude = latitude
        self.longitude = longitude
        self.$repository.id = repositoryId
        self.$user.id = userId
    }
}

extension WaypointLocationModel {
    var ownKeyPathOnRepository: KeyPath<WaypointRepositoryModel, ChildrenProperty<WaypointRepositoryModel, WaypointLocationModel>> { \.$locations }
    var _$repository: FluentKit.ParentProperty<WaypointLocationModel, WaypointRepositoryModel> { $repository }
    var _$user: FluentKit.OptionalParentProperty<WaypointLocationModel, UserAccountModel> { $user }
    var _$verifiedAt: OptionalFieldProperty<WaypointLocationModel, Date> { $verifiedAt }
    var _$updatedAt: TimestampProperty<WaypointLocationModel, DefaultTimestampFormat> { $updatedAt }
    var _$deletedAt: TimestampProperty<WaypointLocationModel, DefaultTimestampFormat> { $deletedAt }
}

extension WaypointLocationModel {
    var location: Waypoint.Location {
        .init(latitude: self.latitude, longitude: self.longitude)
    }
}
