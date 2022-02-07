//
//  UserApiDeleteTests.swift
//  
//
//  Created by niklhut on 24.05.20.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class UserApiDeleteTests: AppTestCaseWithModeratorAndNormalToken {
    let usersPath = "api/\(User.pathKey)/\(User.Account.pathKey)/"
    
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-user@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> UserAccountModel {
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: verified, role: role)
        try await user.create(on: app.db)
        return user
    }
    
    private func createNewUserWithToken(
        name: String = "New Test User",
        email: String = "test-user@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> (user: UserAccountModel, token: String) {
        let user = try await createNewUser(name: name, email: email, school: school, password: password, verified: verified, role: role)
        let token = try user.generateToken()
        try await token.create(on: app.db)
        
        return (user, token.value)
    }
    
    func testSuccessfulDeleteUserSelf() async throws {
        let (user, token) = try await createNewUserWithToken()
        
        // Get original user count
        let userCount = try await UserAccountModel.query(on: app.db).count()
        
        try app
            .describe("User should be able to delte himself; Delete user should return ok")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.noContent)
            .test()
        
        // New user count should be one less than original user count
        let newUserCount = try await UserAccountModel.query(on: app.db).count()
        XCTAssertEqual(newUserCount, userCount - 1)
    }
    
    func testSuccessfulDeleteUserFromAdmin() async throws {
        let user = try await createNewUser()
        
        // Get original user count
        let userCount = try await UserAccountModel.query(on: app.db).count()
        
        try app
            .describe("Admin should be able to delete user; Delete user should return ok")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New user count should be one less than original user count
        let newUserCount = try await UserAccountModel.query(on: app.db).count()
        XCTAssertEqual(newUserCount, userCount - 1)
    }
    
    func testsDeleteUserFromNonAdminFails() async throws {
        let user = try await createNewUser()
        
        try app
            .describe("Non admin user should not be able to delete other user; Delete user should fail")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteUserDeletesTokens() async throws {
        let user = try await createNewUser()
        
        try app
            .describe("Deleting a user should delte all tokens belonging to him")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        let deletedUserTokenCount = try await UserTokenModel.query(on: app.db).filter(\.$user.$id, .equal, user.id!).count()
        XCTAssertEqual(deletedUserTokenCount, 0)
    }
    
    func testDeleteUserWithoutTokenFails() async throws {
        let user = try await createNewUser()
        
        try app
            .describe("Delete user without bearer token fails")
            .delete(usersPath.appending(user.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingUserFails() throws {
        try app
            .describe("Deleting a user which does not exist fails")
            .delete(usersPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
}
