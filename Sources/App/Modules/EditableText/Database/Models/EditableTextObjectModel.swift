//
//  EditableTextObjectModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent
import Foundation
import CloudKit

final class EditableTextObjectModel: DatabaseModelInterface, NodeModel {
    typealias Module = EditableTextModule
    
    struct FieldKeys {
        struct v1 {
            static var value: FieldKey { "value" }
            static var previousId: FieldKey { "previous_id" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.value) var value: String
    @OptionalChild(for: \.$previous) var next: EditableTextObjectModel?
    @OptionalParent(key: FieldKeys.v1.previousId) var previous: EditableTextObjectModel?
    
    var nextProperty: OptionalChildProperty<EditableTextObjectModel, EditableTextObjectModel> { $next }
    var previousProperty: OptionalParentProperty<EditableTextObjectModel, EditableTextObjectModel> { $previous }
    
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    
    init() { }
    
    init(value: String) {
        self.value = value
    }
    
    init(
        value: String,
        userId: UUID
    ) {
        self.value = value
        self.$user.id = userId
    }
    
    init(
        id: UUID? = nil,
        value: String,
        previousId: UUID?,
        userId: UUID
    ) {
        self.id = id
        self.value = value
        self.$previous.id = previousId
        self.$user.id = userId
    }
}

extension EditableTextObjectModel: Equatable {
    static func == (lhs: EditableTextObjectModel, rhs: EditableTextObjectModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.value == rhs.value
    }
}
