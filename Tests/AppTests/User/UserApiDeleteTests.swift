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

final class UserApiDeleteTests: AppTestCase, UserTest {
    func testSuccessfulDeleteUserSelf() async throws {
        let (user, token) = try await createNewUserWithToken()
        
        // Get original user count
        let userCount = try await UserAccountModel.query(on: app.db).count()
        
        try app
            .describe("User should be able to delete himself; Delete user should return ok")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.noContent)
            .test()
        
        // New user count should be one less than original user count
        let newUserCount = try await UserAccountModel.query(on: app.db).count()
        XCTAssertEqual(newUserCount, userCount - 1)
    }
    
    func testSuccessfulDeleteUserFromAdmin() async throws {
        let moderatorToken = try await getToken(for: .admin)
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
    
    func testsDeleteUserFromModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        let user = try await createNewUser()
        
        try app
            .describe("Non admin user should not be able to delete other user; Delete user should fail")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testsDeleteUserFromNormalUserFails() async throws {
        let token = try await getToken(for: .user)
        let user = try await createNewUser()
        
        try app
            .describe("Non admin user should not be able to delete other user; Delete user should fail")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteUserDeletesTokens() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let user = try await createNewUser()
        
        try app
            .describe("Deleting a user should delete all tokens belonging to him")
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
    
    func testDeleteNonExistingUserFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Deleting a user which does not exist fails")
            .delete(usersPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
}
