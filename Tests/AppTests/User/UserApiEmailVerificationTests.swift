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

final class UserApiEmailVerificationTests: AppTestCase, UserTest {
    // MARK: - request verification
    
    func testSuccessfulRequestVerification() async throws {
        let (user, token) = try await createNewUserWithToken()
        XCTAssertFalse(user.verified)
        
        try app
            .describe("User should successfully request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.ok)
            .test()
    }
    
    func testRequestVerificationDeletesOldTokens() async throws {
        let (user, token) = try await createNewUserWithToken()
        XCTAssertFalse(user.verified)
        
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
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.ok)
            .test()
        
        let newVerificationTokens = try await UserVerificationTokenModel.query(on: app.db).all()
        XCTAssertEqual(newVerificationTokens.count, verificationTokenCount + 1)
        XCTAssertNotEqual(newVerificationTokens.first!.value, verificationToken.value)
    }
    
    func testRequestVerificationFromDifferentUserFails() async throws {
        let user = try await createNewUser()
        XCTAssertFalse(user.verified)
        
        let token = try await getToken(for: .user)
        let moderatorToken = try await getToken(for: .moderator)
        
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
        let (user, token) = try await createNewUserWithToken(verified: true)
        XCTAssertTrue(user.verified)
        
        try app
            .describe("Verified user should not be able to request verification")
            .post(usersPath.appending(user.requireID().uuidString).appending("/requestVerification"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testRequestVerificationWihtoutTokenFails() async throws {
        let user = try await createNewUser()
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
        let (user, token) = try await createNewUserWithToken()
        XCTAssertFalse(user.verified)
        
        // Get original verification token count
        let verificationTokenCount = try await UserVerificationTokenModel.query(on: app.db).count()
        
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
        XCTAssertEqual(verificationTokens.count, verificationTokenCount)
    }
    
    func testSuccessfulUserVerificationWithoutBearerToken() async throws {
        let user = try await createNewUser()
        XCTAssertFalse(user.verified)
        
        // Get original verification token count
        let verificationTokenCount = try await UserVerificationTokenModel.query(on: app.db).count()
        
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
        XCTAssertEqual(verificationTokens.count, verificationTokenCount)
    }
    
    func testVerificationWithWrongVerificationTokenFails() async throws {
        let user = try await createNewUser()
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
        let user = try await createNewUser()
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
        let user = try await createNewUser()
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
