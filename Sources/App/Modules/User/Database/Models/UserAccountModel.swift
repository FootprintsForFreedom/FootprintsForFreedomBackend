//
//  UserAccountModel.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent
import AppApi

final class UserAccountModel: DatabaseModelInterface {
    typealias Module = UserModule
    
    struct FieldKeys {
        struct v1 {
            static var name: FieldKey { "name" }
            static var email: FieldKey { "email" }
            static var school: FieldKey { "school" }
            static var password: FieldKey { "password" }
            static var verified: FieldKey { "verified" }
            static var role: FieldKey { "role" }
        }
    }
    
    @ID() var id: UUID?
    @Field(key: FieldKeys.v1.name) var name: String
    @Field(key: FieldKeys.v1.email) var email: String
    @OptionalField(key: FieldKeys.v1.school) var school: String?
    @Field(key: FieldKeys.v1.password) private(set) var password: String
    @Field(key: FieldKeys.v1.verified) var verified: Bool
    @Enum(key: FieldKeys.v1.role) var role: User.Role
    
    @OptionalChild(for: \.$user) var verificationToken: UserVerificationTokenModel?
    
    init() { }
    
    init(id: UUID? = nil,
         name: String,
         email: String,
         school: String?,
         password: String,
         verified: Bool,
         role: User.Role
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.school = school
        self.password = password
        self.verified = verified
        self.role = role
    }
}

extension UserAccountModel {
    func setPassword(to newPassword: String, on req: Request) throws {
        /// Confirm new password meets conditions
        guard newPassword.count >= 6 &&
                newPassword.rangeOfCharacter(from: .uppercaseLetters) != nil &&
                newPassword.rangeOfCharacter(from: .lowercaseLetters) != nil &&
                newPassword.rangeOfCharacter(from: .decimalDigits) != nil &&
                newPassword.rangeOfCharacter(from: .newlines) == nil
        else {
            throw Abort(.badRequest, reason: "Password does not meet requirements")
        }
        /// Update the password
        self.password = try req.application.password.hash(newPassword)
    }
    
    func publicDetail() throws -> User.Account.Detail {
        return try .publicDetail(id: self.requireID(), name: self.name, school: self.school)
    }
}
