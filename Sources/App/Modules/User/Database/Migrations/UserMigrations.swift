//
//  UserMigrations.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent
import AppApi

enum UserMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let userRole = try await db.enum(User.Role.pathKey)
                .case(User.Role.user.rawValue)
                .case(User.Role.moderator.rawValue)
                .case(User.Role.admin.rawValue)
                .case(User.Role.superAdmin.rawValue)
                .create()
            
            try await db.schema(UserAccountModel.schema)
                .id()
                .field(UserAccountModel.FieldKeys.v1.name, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.email, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.school, .string)
                .field(UserAccountModel.FieldKeys.v1.password, .string, .required)
                .field(UserAccountModel.FieldKeys.v1.verified, .bool, .sql(.default(false)))
                .field(UserAccountModel.FieldKeys.v1.role, userRole, .required)
                .unique(on: UserAccountModel.FieldKeys.v1.email)
                .create()
            
            try await db.schema(UserTokenModel.schema)
                .id()
                .field(UserTokenModel.FieldKeys.v1.value, .string, .required)
                .field(UserTokenModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(UserTokenModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .cascade)
                .unique(on: UserTokenModel.FieldKeys.v1.value)
                .create()
            
            try await db.schema(UserVerificationTokenModel.schema)
                .id()
                .field(UserVerificationTokenModel.FieldKeys.v1.value, .string, .required)
                .field(UserVerificationTokenModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(UserVerificationTokenModel.FieldKeys.v1.userId, .uuid, .required)
                .foreignKey(UserVerificationTokenModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .cascade)
                .unique(on: UserVerificationTokenModel.FieldKeys.v1.value)
                .unique(on: UserVerificationTokenModel.FieldKeys.v1.userId)
                .create()
        }
        
        func revert(on db: Database) async throws  {
            try await db.schema(UserTokenModel.schema).delete()
            try await db.schema(UserVerificationTokenModel.schema).delete()
            try await db.schema(UserAccountModel.schema).delete()
            try await db.enum(User.Role.pathKey).delete()
        }
    }
    
    struct seed: AsyncMigration {
        func prepare(on db: Database) async throws {
            let email = "root@localhost.com"
            let password = "ChangeMe1"
            let user = UserAccountModel(name: "MyAdmin", email: email, school: "schule", password: try Bcrypt.hash(password), verified: true, role: .superAdmin)
            user.role = .superAdmin
            try await user.create(on: db)
        }
        
        func revert(on db: Database) async throws {
            try await UserAccountModel.query(on: db).delete()
        }
    }
    
}
