//
//  UserApiUpdatePasswordTests.swift
//  
//
//  Created by niklhut on 24.05.20.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.ChangePassword: Content {}

final class UserApiUpdatePasswordTests: AppTestCase {
    let usersPath = "api/\(User.pathKey)/\(User.Account.pathKey)/"

    private func getUserUpdatePasswordContent(
        initialPassword: String = "password",
        currentPassword: String = "password",
        newPassword: String = "1newPassword"
    ) async throws -> (model: UserAccountModel, token: String, updatePasswordContent: User.Account.ChangePassword) {
        let name = "New Test User"
        let email = "new-test-user\(UUID())@example.com"
        let school: String? = nil
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(initialPassword), verified: false, role: .user)
        try await user.create(on: app.db)
        
        let token = try user.generateToken()
        try await token.save(on: app.db)
        
        let updatedUser = User.Account.ChangePassword(currentPassword: currentPassword, newPassword: newPassword)
        return (user, token.value, updatedUser)
    }
    
    func testSuccessfulUpdateUserPassword() async throws {
        let (user, token, updatePasswordContent) = try await getUserUpdatePasswordContent()
        
        try app
            .describe("Update user password should return ok")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(token)
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
    
    func testNewPasswordNeedsUppercasedLetter() async throws {
        let (user, token, updatePasswordContent) = try await getUserUpdatePasswordContent(newPassword: "1newpassword")
        
        try app
            .describe("New user password needs at least one uppercased letter; Update password fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsLowercasedLetter() async throws {
        let (user, token, updatePasswordContent) = try await getUserUpdatePasswordContent(newPassword: "1NEWPASSWORD")
        
        try app
            .describe("New user password needs at least one lowercased letter; Update password fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsDigit() async throws {
        let (user, token, updatePasswordContent) = try await getUserUpdatePasswordContent(newPassword: "newPassword")
        
        try app
            .describe("New user password needs at least one digit; Update password fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordWihtNewLineFails() async throws {
        let (user, token, updatePasswordContent) = try await getUserUpdatePasswordContent(newPassword: "1new\nPassword")
        
        try app
            .describe("New user password must not contain new line; Update password fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCurrentPasswordMustBeValid() async throws {
        let user = try await getUserUpdatePasswordContent(currentPassword: "wrongPassword")
        
        try app
            .describe("Current user password must be valid; Update password fails")
            .put(usersPath.appending(user.model.requireID().uuidString.appending("/updatePassword")))
            .body(user.updatePasswordContent)
            .bearerToken(user.token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateUserPasswordFromDifferentUserFails() async throws {
        let (user, _, updatePasswordContent) = try await getUserUpdatePasswordContent()
        let token = try await getTokenFromOtherUser(role: .user)
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("Update user password from different user fails; Update password fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
        
        try app
            .describe("Update user password from different admin user fails; Update password fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateUserPasswordWithoutTokenFails() async throws {
        let (user, _, updatePasswordContent) = try await getUserUpdatePasswordContent()
        
        try app
            .describe("Update user without bearer token fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(updatePasswordContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateUserPasswordWithWrongPayloadFails() async throws {
        let (user, token, _) = try await getUserUpdatePasswordContent()
        
        try app
            .describe("Updating a user with wrong payload fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/updatePassword")))
            .body(["wrong input": "Test Category"])
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
}
