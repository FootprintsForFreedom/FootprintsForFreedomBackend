//
//  UserApiGetTests.swift
//  
//
//  Created by niklhut on 24.05.20.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class UserApiGetTests: AppTestCaseWithAdminAndNormalToken {
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
    
    func testSuccesfullListUsers() async throws {
        let user = try await createNewUser()
        
        // Get user count
        let userCount = try await UserAccountModel.query(on: app.db).count()
        
        try app
            .describe("List users with admin token should return ok and all saved entries")
            .get(usersPath)
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<User.Account.List>.self) { content in
                XCTAssertEqual(content.items.count, userCount)
                XCTAssert(content.items.contains { $0.id == user.id })
        }
        .test()
    }
    
    func testListUsersWithNormalTokenFails() async throws {
        try app
            .describe("List users should fail with normal token")
            .get(usersPath)
            .bearerToken(token)
            .expect(.forbidden)
            .expect(.json)
            .test()
    }
    
    func testListUsersWithoutTokenFails() throws {
        try app
            .describe("List users wihtout token should fail")
            .get(usersPath)
            .expect(.unauthorized)
            .test()
    }
    
    func testGetUserAsSelf() async throws {
        let user = try await createNewUser()
        let ownToken = try user.generateToken()
        try await ownToken.create(on: app.db)
        
        try app
            .describe("Get user should reutrn ok")
            .get(usersPath.appending(user.requireID().uuidString))
            .bearerToken(ownToken.value)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
        }
        .test()
    }
    
    func testGetUserAsModerator() async throws {
        let user = try await createNewUser()
        
        try app
            .describe("Get user should return ok")
            .get(usersPath.appending(user.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
        }
        .test()

    }
    
    func testGetUserAsNormalUser() async throws {
        let user = try await createNewUser()
        
        try app
            .describe("Get user should reutrn ok")
            .get(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertNil(content.verified)
                XCTAssertNil(content.role)
        }
        .test()
    }
    
    func testGetUserWithoutToken() async throws {
        let user = try await createNewUser()
        
        try app
            .describe("Get user should reutrn ok")
            .get(usersPath.appending(user.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertNil(content.verified)
                XCTAssertNil(content.role)
        }
        .test()
    }
}
