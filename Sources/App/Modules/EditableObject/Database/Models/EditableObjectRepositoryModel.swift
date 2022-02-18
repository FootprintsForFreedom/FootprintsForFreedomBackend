//
//  EditableObjectRepositoryModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent

final class EditableObjectRepositoryModel<T>: DatabaseModelInterface, LinkedListModel where T: Codable, T: Equatable {
    typealias Module = EditableObjectModule
    typealias NodeObject = EditableObjectModel<T>
    
    static var identifier: String { "repositories" }
    
    struct FieldKeys {
        struct v1 {
            static var currentId: FieldKey { "current_id" }
            static var lastId: FieldKey { "last_id" }
        }
    }
    
    @ID() var id: UUID?
    @OptionalParent(key: FieldKeys.v1.currentId) var current: EditableObjectModel<T>!
    @OptionalParent(key: FieldKeys.v1.lastId) var last: EditableObjectModel<T>!
    
    var currentProperty: OptionalParentProperty<EditableObjectRepositoryModel<T>, EditableObjectModel<T>> { $current }
    var lastProperty: OptionalParentProperty<EditableObjectRepositoryModel<T>, EditableObjectModel<T>> { $last }
    
    init() { }
}

extension EditableObjectRepositoryModel {
    @discardableResult
    func append(_ value: Element, submittedBy userId: UserAccountModel.IDValue, on req: Request) async throws -> NodeObject {
        let newNode = NodeObject(value: value, userId: userId)
        return try await self.append(newNode, on: req)
    }
}
