//
//  EditableObjectModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent
import Foundation
import CloudKit

final class EditableObjectModel<T>: DatabaseModelInterface, NodeModel where T: Codable, T: Equatable {
    typealias Module = EditableObjectModule
    
    static var identifier: String { "objects" }
    
    struct FieldKeys {
        struct v1 {
            static var value: FieldKey { "value" }
            static var previousId: FieldKey { "previous_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.value) var value: T
    @OptionalChild(for: \.$previous) var next: EditableObjectModel<T>?
    @OptionalParent(key: FieldKeys.v1.previousId) var previous: EditableObjectModel<T>?
    
    var nextProperty: OptionalChildProperty<EditableObjectModel<T>, EditableObjectModel<T>> { $next }
    var previousProperty: OptionalParentProperty<EditableObjectModel<T>, EditableObjectModel<T>> { $previous }
    
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    
    init() { }
    
    init(value: T) {
        self.value = value
    }
    
    init(
        value: T,
        userId: UUID
    ) {
        self.value = value
        self.$user.id = userId
    }
    
    init(
        id: UUID? = nil,
        value: T,
        previousId: UUID?,
        userId: UUID
    ) {
        self.id = id
        self.value = value
        self.$previous.id = previousId
        self.$user.id = userId
    }
}

extension EditableObjectModel: Equatable {
    static func == (lhs: EditableObjectModel<T>, rhs: EditableObjectModel<T>) -> Bool {
        lhs.id == rhs.id &&
        lhs.value == rhs.value
    }
}
