//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

final class UserAccountModel: DatabaseModelInterface {
    typealias Module = UserModule
    
    struct FieldKeys {
        struct v1 {
            static var name: FieldKey { "name" }
            static var email: FieldKey { "email" }
            static var school: FieldKey { "school" }
            static var password: FieldKey { "password" }
            static var verified: FieldKey { "verified" }
            static var isModerator: FieldKey { "is_moderator" }
        }
    }

    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.name) var name: String
    @Field(key: FieldKeys.v1.email) var email: String
    @Field(key: FieldKeys.v1.school) var school: String
    @Field(key: FieldKeys.v1.password) var password: String
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Field(key: FieldKeys.v1.isModerator) var isModerator: Bool
    
    init() { }
    
    init(id: UUID? = nil,
         name: String,
         email: String,
         school: String,
         password: String,
         verified: Bool)
    {
        self.id = id
        self.name = name
        self.email = email
        self.school = school
        self.password = password
        self.verified = verified
    }
}
