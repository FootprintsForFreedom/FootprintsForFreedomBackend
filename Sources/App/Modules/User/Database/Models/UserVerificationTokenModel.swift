//
//  UserVerificationTokenModel.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

final class UserVerificationTokenModel: DatabaseModelInterface {
    typealias Module = UserModule
        
    struct FieldKeys {
        struct v1 {
            static var value: FieldKey { "value" }
            static var userId: FieldKey { "user_id" }
            static var createdAt: FieldKey { "created_at" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.value) var value: String
    @Timestamp(key: FieldKeys.v1.createdAt, on: .create) var createdAt: Date?
    @Parent(key: FieldKeys.v1.userId) var user: UserAccountModel

    init() { }
    
    init(id: UUID? = nil,
         value: String,
         userId: UUID)
    {
        self.id = id
        self.value = value
        self.$user.id = userId
    }
}
