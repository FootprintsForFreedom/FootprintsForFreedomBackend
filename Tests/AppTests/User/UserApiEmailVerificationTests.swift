//
//  UserApiEmailVerificationTests.swift
//  
//
//  Created by niklhut on 06.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.Verification: Content {}

final class UserApiEmailVerificationTests: AppTestCase {
    let usersPath = "api/\(User.pathKey)/\(User.Account.pathKey)/"
    
    private func createNewUser(
        verified: Bool = false
    ) async throws -> (model: UserAccountModel, token: String) {
        let name = "New Test User"
        let email = "new-test-user\(UUID())@example.com"
        let school: String? = nil
        let password = "password7293"
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: verified, role: .user)
        try await user.create(on: app.db)
        
        let token = try user.generateToken()
        try await token.save(on: app.db)
        
        return (user, token.value)
    }
    
    // MARK: - request verification
    
    func testSuccessfulRequestVerification() async throws {
        let (user, token) = try await createNewUser()
        XCTAssertFalse(user.verified)
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.ok)
            .test()
    }
    
    func testRequestVerificationDeletesOldTokens() async throws {
        let (user, token) = try await createNewUser()
        XCTAssertFalse(user.verified)
        
        let verificationToken = try user.generateVerificationToken()
        try await verificationToken.save(on: app.db)
        
        let verificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(verificationTokens.count, 1)
        XCTAssertEqual(verificationTokens.first!.value, verificationToken.value)
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.ok)
            .test()
        
        let newVerificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(newVerificationTokens.count, 1)
        XCTAssertNotEqual(newVerificationTokens.first!.value, verificationToken.value)
    }
    
    func testRequestVerificationFromDifferentUserFails() async throws {
        let (user, _) = try await createNewUser()
        XCTAssertFalse(user.verified)
        
        let token = try await getTokenFromOtherUser(role: .user)
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("Different user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
        
        try app
            .describe("Different admin user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }
    
    func testRequestVerificationFromVerifiedUserFails() async throws {
        let (user, token) = try await createNewUser(verified: true)
        XCTAssertTrue(user.verified)
        
        try app
            .describe("Verified user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testRequestVerificationWihtoutTokenFails() async throws {
        let (user, _) = try await createNewUser()
        XCTAssertFalse(user.verified)
        
        try app
            .describe("Request verification without bearer token fails")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .expect(.unauthorized)
            .test()
    }
    
    // MARK: - verification
    
    private func verificationToken(for user: UserAccountModel) async throws -> UserVerificationTokenModel {
        let verificationToken = try user.generateVerificationToken()
        try await verificationToken.save(on: app.db)
        return verificationToken
    }
    
    func testSuccessfulUserVerificationWhenSignedIn() async throws {
        let (user, token) = try await createNewUser()
        XCTAssertFalse(user.verified)
        let verificationToken = try await verificationToken(for: user)
        
        let urlQuery = "?token=\(verificationToken.value)"
        
        try app
            .describe("User should be verified successfully and get own detail content when signed in")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify\(urlQuery)")))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, true)
                XCTAssertEqual(content.role, user.role)
        }
        .test()
        
        // check token is deleted after verification
        let verificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(verificationTokens.count, 0)
    }
    
    func testSuccessfulUserVerificationWithoutBearerToken() async throws {
        let (user, _) = try await createNewUser()
        XCTAssertFalse(user.verified)
        let verificationToken = try await verificationToken(for: user)
        
        let urlQuery = "?token=\(verificationToken.value)"
        
        try app
            .describe("User should be verified successfully and get public detail content when not signed in")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify\(urlQuery)")))
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.school, user.school)
        }
        .test()
        
        // check token is deleted after verification
        let verificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(verificationTokens.count, 0)
    }
    
    func testVerificationWithWrongVerificationTokenFails() async throws {
        let (user, _) = try await createNewUser()
        XCTAssertFalse(user.verified)
        let _ = try await verificationToken(for: user)
        let wrongVerificationToken = try user.generateVerificationToken()
        
        let urlQuery = "?token=\(wrongVerificationToken.value)"
        
        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify\(urlQuery)")))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerificationWithoutSavedTokenFails() async throws {
        let (user, _) = try await createNewUser()
        XCTAssertFalse(user.verified)
        let wrongVerificationToken = try user.generateVerificationToken()
        
        let urlQuery = "?token=\(wrongVerificationToken.value)"
        
        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify\(urlQuery)")))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerificationWithOldTokenFails() async throws {
        let (user, _) = try await createNewUser()
        XCTAssertFalse(user.verified)
        let verificationToken = try await verificationToken(for: user)
        // Set the created date back one day
        verificationToken.createdAt = Date() - (60 * 60 * 60 * 24)
        try await verificationToken.update(on: app.db)
        XCTAssertGreaterThan(abs(verificationToken.createdAt!.timeIntervalSinceNow), 60 * 60 * 60 * 24)
        
        let urlQuery = "?token=\(verificationToken.value)"
        
        try app
            .describe("User should not be verified")
            .post(usersPath.appending(user.requireID().uuidString.appending("/verify\(urlQuery)")))
            .expect(.unauthorized)
            .test()
    }
}
