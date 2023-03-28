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

final class UserApiGetTests: AppTestCase, UserTest {
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-user\(UUID())@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> UserAccountModel {
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: verified, role: role)
        try await user.create(on: app.db)
        return user
    }
    
    func testSuccessfulListUsers() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let user = try await createNewUser()
        
        // Get user count
        let userCount = try await UserAccountModel.query(on: app.db).count()
        
        try app
            .describe("List users with admin token should return ok and all saved entries")
            .get(usersPath)
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<User.Account.List>.self) { content in
                XCTAssertEqual(content.metadata.total, userCount)
                if userCount < content.items.count {
                    XCTAssert(content.items.contains { $0.id == user.id })
                }
        }
        .test()
    }
    
    func testListUsersAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        
        try app
            .describe("List users should fail with normal token")
            .get(usersPath)
            .bearerToken(token)
            .expect(.forbidden)
            .expect(.json)
            .test()
    }
    
    func testListUsersWithNormalTokenFails() async throws {
        let token = try await getToken(for: .user)
        
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
            .describe("List users without token should fail")
            .get(usersPath)
            .expect(.unauthorized)
            .test()
    }
    
    func testGetUserAsSelf() async throws {
        let user = try await createNewUser()
        let ownToken = try user.generateToken()
        try await ownToken.create(on: app.db)
        
        try app
            .describe("Get user should return ok")
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
    
    func testGetUserAsAdmin() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let user = try await createNewUser()
        
        try app
            .describe("Get user should return ok")
            .get(usersPath.appending(user.requireID().uuidString))
            .bearerToken(moderatorToken)
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
    
    func testGetUserAsSuperAdmin() async throws {
        let user = try await createNewUser()
        let superAdminToken = try await getToken(for: .superAdmin)
        
        try app
            .describe("Get user should return ok")
            .get(usersPath.appending(user.requireID().uuidString))
            .bearerToken(superAdminToken)
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
    
    func testGetUserAsNormalUser() async throws {
        let token = try await getToken(for: .user)
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
