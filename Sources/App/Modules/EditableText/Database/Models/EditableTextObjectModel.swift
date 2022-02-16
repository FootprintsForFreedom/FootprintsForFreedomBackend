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
            static var currentObjectInListWithId: FieldKey { "current_object_in_list_with_id" }
            static var lastObjectInListWithId: FieldKey { "last_object_in_list_with_id" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.value) var value: String
    @OptionalChild(for: \.$previous) var next: EditableTextObjectModel?
    @OptionalParent(key: FieldKeys.v1.previousId) var previous: EditableTextObjectModel?
    
    var nextProperty: OptionalChildProperty<EditableTextObjectModel, EditableTextObjectModel> { $next }
    var previousProperty: OptionalParentProperty<EditableTextObjectModel, EditableTextObjectModel> { $previous }
    
    @OptionalParent(key: FieldKeys.v1.currentObjectInListWithId) var currentObjectInList: EditableTextRepositoryModel?
    @OptionalParent(key: FieldKeys.v1.lastObjectInListWithId) var lastObjectInList: EditableTextRepositoryModel?
    
    var currentObjectInListProperty: OptionalParentProperty<EditableTextObjectModel, EditableTextRepositoryModel> { $currentObjectInList }
    var lastObjectInListProperty: OptionalParentProperty<EditableTextObjectModel, EditableTextRepositoryModel> { $lastObjectInList }
    
    init() { }
    
    init(value: String) {
        self.value = value
    }
    
    init(
        id: UUID? = nil,
        value: String,
        previousId: UUID?
    ) {
        self.id = id
        self.value = value
        self.$previous.id = previousId
    }
}

extension EditableTextObjectModel: Equatable {
    static func == (lhs: EditableTextObjectModel, rhs: EditableTextObjectModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.value == rhs.value
    }
}
