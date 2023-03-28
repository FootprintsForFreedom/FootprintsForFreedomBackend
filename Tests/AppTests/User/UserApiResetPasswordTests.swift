//
//  UserApiResetPasswordTests.swift
//  
//
//  Created by niklhut on 06.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.ResetPasswordRequest: Content {}
extension User.Account.ResetPassword: Content {}

final class UserApiResetPasswordTests: AppTestCase, UserTest {
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-use\(UUID())r@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> UserAccountModel {
        let user = UserAccountModel(name: name, email: email, school: school, password: password, verified: verified, role: role)
        try await user.create(on: app.db)
        return user
    }
    
    // MARK: - request reset password
    
    private func resetPasswordRequest(for user: UserAccountModel) -> User.Account.ResetPasswordRequest{
        return User.Account.ResetPasswordRequest(email: user.email)
    }
    
    func testSuccessfulRequestResetPassword() async throws {
        let user = try await createNewUser()
        let resetPasswordRequest = resetPasswordRequest(for: user)
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest)
            .expect(.ok)
            .test()
    }
    
    func testRequestResetPasswordDeletesOldTokens() async throws {
        let user = try await createNewUser()
        let resetPasswordRequest = resetPasswordRequest(for: user)
        
        // Get original verification token count
        let verificationTokenCount = try await UserVerificationTokenModel.query(on: app.db).count()
        
        let verificationToken = try user.generateVerificationToken()
        try await verificationToken.save(on: app.db)
        
        let verificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(verificationTokens.count, verificationTokenCount + 1)
        XCTAssert(verificationTokens.contains { $0.$user.id == user.id })
        XCTAssertEqual(verificationTokens.first { $0.$user.id == user.id }!.value, verificationToken.value)
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest)
            .expect(.ok)
            .test()
        
        let newVerificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(newVerificationTokens.count, verificationTokenCount + 1)
        XCTAssertNotEqual(newVerificationTokens.first!.value, verificationToken.value)
    }
    
    func testRequestResetPasswordWithWrongEmailFails() async throws {
        let resetPasswordRequest1 = User.Account.ResetPasswordRequest(email: "")
        let resetPasswordRequest2 = User.Account.ResetPasswordRequest(email: "test@test")
        let resetPasswordRequest3 = User.Account.ResetPasswordRequest(email: "@test.com")
        let resetPasswordRequest4 = User.Account.ResetPasswordRequest(email: "test.com")
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest1)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest2)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest3)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending("resetPassword"))
            .body(resetPasswordRequest4)
            .expect(.badRequest)
            .test()
    }
    
    // MARK: - reset password
    
    private func verificationToken(for user: UserAccountModel) async throws -> UserVerificationTokenModel {
        let verificationToken = try user.generateVerificationToken()
        try await verificationToken.save(on: app.db)
        return verificationToken
    }
    
    private func resetPasswordContent(for user: UserAccountModel, with newPassword: String) async throws -> User.Account.ResetPassword {
        let verificationToken = try user.generateVerificationToken()
        try await verificationToken.save(on: app.db)

        let resetPassword = User.Account.ResetPassword(token: verificationToken.value, newPassword: newPassword)
        return resetPassword
    }
    
    func testSuccessfulResetPassword() async throws {
        let password = "password7293"
        let user = try await createNewUser(password: password)
        let newPassword = "my3NewPassword"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        
        try app
            .describe("User should successfully reset password")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertNil(content.verified)
                XCTAssertNil(content.role)
                Task {
                    guard let user = try await UserAccountModel.find(user.id, on: self.app.db) else {
                        XCTFail()
                        return
                    }
                    // User is verified after password reset since he has access to his email
                    XCTAssertEqual(user.verified, true)
                }
            }
            .test()
        
        // test user can sign in with new password
        let signInPath = "/api/v1/sign-in/"
        let credentials = User.Account.Login(email: user.email, password: newPassword)
        
        try app
            .describe("Credentials login should return ok with new password")
            .post(signInPath)
            .body(credentials)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.access_token.count, 64)
                XCTAssertEqual(content.user.email, user.email)
            }
            .test()
        
        // test user cannot sign in with old password
        let oldCredentials = User.Account.Login(email: user.email, password: password)
        
        try app
            .describe("Credentials login should fail with old password")
            .post(signInPath)
            .body(oldCredentials)
            .expect(.unauthorized)
            .test()
    }
    
    func testNewPasswordNeedsAtLeastSixCharacters() async throws {
        let user = try await createNewUser()
        let newPassword = "1aB"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        
        try app
            .describe("New user password needs at least six characters; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.badRequest)
            .test()
    }

    
    func testNewPasswordNeedsUppercasedLetter() async throws {
        let user = try await createNewUser()
        let newPassword = "alllowwercase34"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        
        try app
            .describe("New user password needs at least one uppercased letter; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsLowercasedLetter() async throws {
        let user = try await createNewUser()
        let newPassword = "1NEWPASSWORD"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)

        try app
            .describe("New user password needs at least one lowercased letter; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsDigit() async throws {
        let user = try await createNewUser()
        let newPassword = "myNewPassword"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        
        try app
            .describe("New user password needs at least one digit; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordWihtNewLineFails() async throws {
        let user = try await createNewUser()
        let newPassword = "my3New\nPassword"
        let resetPasswordContent = try await resetPasswordContent(for: user, with: newPassword)
        
        try app
            .describe("New user password must not contain new line; Update password fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.badRequest)
            .test()
    }
    
    func testResetPasswordWithWrongVerificationTokenFails() async throws {
        let user = try await createNewUser()
        
        let _ = try await verificationToken(for: user)
        let wrongVerificationToken = try user.generateVerificationToken()
        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(token: wrongVerificationToken.value, newPassword: newPassword)
        
        try app
            .describe("User should not be able to reset password")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testVerificationWithoutSavedTokenFails() async throws {
        let user = try await createNewUser()
        
        let wrongVerificationToken = try user.generateVerificationToken()
        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(token: wrongVerificationToken.value, newPassword: newPassword)
        
        try app
            .describe("User should not be able to reset password")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testVerificationWithOldTokenFails() async throws {
        let user = try await createNewUser()
        
        let verificationToken = try await verificationToken(for: user)
        verificationToken.createdAt = Date() - (60 * 60 * 60 * 24)
        try await verificationToken.update(on: app.db)
        let newPassword = "my3NewPassword"
        let resetPasswordContent = User.Account.ResetPassword(token: verificationToken.value, newPassword: newPassword)
        XCTAssertGreaterThan(abs(verificationToken.createdAt!.timeIntervalSinceNow), 60 * 60 * 60 * 24)
        
        
        try app
            .describe("User should not be able to reset password")
            .post(usersPath.appending(user.requireID().uuidString).appending("/resetPassword"))
            .body(resetPasswordContent)
            .expect(.unauthorized)
            .test()
    }
}
