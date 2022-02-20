//
//  WaypointRepositoryModel.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import Vapor
import Fluent

final class WaypointRepositoryModel: LinkedListModel {
    typealias Module = WaypointModule
    typealias NodeObject = WaypointWaypointModel
    
    static var identifier: String { "repositories" }
    
    struct FieldKeys {
        struct v1 {
            static var verified: FieldKey { "verified" }
            static var currentId: FieldKey { "current_id" }
            static var lastId: FieldKey { "last_id" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    
    @Parent(key: FieldKeys.v1.currentId) var current: WaypointWaypointModel
    @Parent(key: FieldKeys.v1.lastId) var last: WaypointWaypointModel
    
    var currentProperty: ParentProperty<WaypointRepositoryModel, WaypointWaypointModel> { $current }
    var lastProperty: ParentProperty<WaypointRepositoryModel, WaypointWaypointModel> { $last }
    
    init() { }
    
    init(verified: Bool) {
        self.verified = verified
    }
}

extension WaypointRepositoryModel {
//    @discardableResult
//    func append(_ value: T, submittedBy userId: UserAccountModel.IDValue, on req: Request) async throws -> NodeObject {
//        let newNode = NodeObject(value: value, userId: userId)
//        return try await self.append(newNode, on: req)
//    }
}
