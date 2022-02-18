//
//  EditableTextRepositoryModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class EditableTextRepositoryModel: DatabaseModelInterface, LinkedListModel {
    
    typealias Module = EditableTextModule
    typealias NodeObject = EditableTextObjectModel
    
    static let identifier = "repositories"
    
    struct FieldKeys {
        struct v1 {
            static var currentId: FieldKey { "current_id" }
            static var lastId: FieldKey { "last_id" }
        }
    }
    
    @ID() var id: UUID?
    @OptionalParent(key: FieldKeys.v1.currentId) var current: EditableTextObjectModel!
    @OptionalParent(key: FieldKeys.v1.lastId) var last: EditableTextObjectModel!
    
    var currentProperty: OptionalParentProperty<EditableTextRepositoryModel, EditableTextObjectModel> { $current }
    var lastProperty: OptionalParentProperty<EditableTextRepositoryModel, EditableTextObjectModel> { $last }
    
    init() { }
}

extension EditableTextRepositoryModel {
    @discardableResult
    func append(_ value: Element, submittedBy userId: UserAccountModel.IDValue, on req: Request) async throws -> NodeObject {
        let newNode = NodeObject(value: value, userId: userId)
        return try await self.append(newNode, on: req)
    }
}
