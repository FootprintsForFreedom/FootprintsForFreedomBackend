//
//  EditableObjectModel.swift
//  
//
//  Created by niklhut on 09.02.22.
//

import Vapor
import Fluent
import Foundation

final class StorableObjectModel<T>: DatabaseModelInterface where T: Codable, T: Equatable {
    typealias Module = StorableModule
    
    static var identifier: String { "objects" }
    
    struct FieldKeys {
        struct v1 {
            static var value: FieldKey { "value" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.value) private var data: Data
    
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    
    var value: T {
        get {
            try! JSONDecoder().decode(T.self, from: data)
        }
        set {
            let data = try! JSONEncoder().encode(newValue)
            self.data = data
        }
    }
    
    init() { }
    
    init(value: T) {
        self.value = value
    }
    
    init(
        id: UUID? = nil,
        value: T,
        userId: UUID
    ) {
        self.id = id
        self.value = value
        self.$user.id = userId
    }
}

extension StorableObjectModel: Equatable {
    static func == (lhs: StorableObjectModel<T>, rhs: StorableObjectModel<T>) -> Bool {
        lhs.id == rhs.id &&
        lhs.value == rhs.value
    }
}
