//
//  UserApiPatchTests.swift
//  
//
//  Created by niklhut on 24.05.20.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.Patch: Content {}

final class UserApiPatchTests: AppTestCase, UserTest {
    private func getUserPatchContent(
        name: String = "New Test User",
        patchedName: String? = nil,
        email: String = "new-test-user\(UUID())@example.com",
        patchedEmail: String? = nil,
        school: String? = nil,
        shouldPatchSchool: Bool = false,
        patchedSchool: String? = nil
    ) async throws -> (model: UserAccountModel, token: String, patchContent: User.Account.Patch) {
        let (user, token) = try await createNewUserWithToken(
            name: name,
            email: email,
            school: school,
            verified: false,
            role: .user
        )
        
        let patchedUser = User.Account.Patch(
            name: patchedName,
            email: patchedEmail,
            setSchool: shouldPatchSchool,
            school: patchedSchool
        )
        return (user, token, patchedUser)
    }
    
    func testEmptyPatchUserDoesNothing() async throws {
        let (user, token, patchContent) = try await getUserPatchContent()
        
        try app
            .describe("Patch username should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
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
    
    func testSuccessfulPatchUserName() async throws {
        let (user, token, patchContent) = try await getUserPatchContent(patchedName: "Patched Test User")
        
        try app
            .describe("Patch username should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, patchContent.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
    }
    
    func testSuccessfulPatchUserEmail() async throws {
        let (user, token, patchContent) = try await getUserPatchContent(patchedEmail: "patched.test-user\(UUID())@example.com")
        
        try app
            .describe("Patch user email should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, patchContent.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
    }
    
    
    func testSuccessfulPatchUserSchoolFromNilToValue() async throws {
        let (user, token, patchContent) = try await getUserPatchContent(shouldPatchSchool: true, patchedSchool: "Meine Schule")
        XCTAssertNil(user.school)
        XCTAssertNotNil(patchContent.school)
        
        try app
            .describe("Patch user school from nil to value should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, patchContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
    }
    
    func testSuccessfulPatchUserSchoolFromValueToValue() async throws {
        let (user, token, patchContent) = try await getUserPatchContent(school: "Meine Schule", shouldPatchSchool: true, patchedSchool: "Meine neue Schule")
        XCTAssertNotNil(user.school)
        XCTAssertNotNil(patchContent.school)
        
        try app
            .describe("Patch user school from value to value should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, patchContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
    }
    
    func testSuccessfulPatchUserSchoolFromValueToNil() async throws {
        let (user, token, patchContent) = try await getUserPatchContent(school: "Meine Schule", shouldPatchSchool: true)
        XCTAssertNotNil(user.school)
        XCTAssertNil(patchContent.school)
        
        try app
            .describe("Patch user email should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, patchContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
    }
    
    func testSuccessfulPatchUserFromDifferentAdminUser() async throws {
        let (user, _, patchContent) = try await getUserPatchContent(patchedName: "Patched Test User")
        let moderatorToken = try await getToken(for: .admin)
        
        try app
            .describe("Patch username from other admin user should return ok")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, patchContent.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.role, user.role)
            }
            .test()
        
    }
    
    func testPatchUserFromDifferentModeratorUserFails() async throws {
        let (user, _, patchContent) = try await getUserPatchContent()
        let token = try await getToken(for: .moderator)
        
        try app
            .describe("Patch user from other non admin user should fail")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchUserFromDifferentNormalUserFails() async throws {
        let (user, _, patchContent) = try await getUserPatchContent()
        let token = try await getToken(for: .user)
        
        try app
            .describe("Patch user from other non admin user should fail")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchUserWithoutTokenFail() async throws {
        let (user, _, patchContent) = try await getUserPatchContent()
        
        try app
            .describe("Patch user without bearer token fails")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testPatchUserNeedsValidName() async throws {
        let (user, token, patchContent) = try await getUserPatchContent(patchedName: "")
        
        try app
            .describe("Patch user without valid name should fail")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchUserNeedsValidEmail() async throws {
        let userOne = try await getUserPatchContent(name: "Test User One", patchedEmail: "")
        let userTwo = try await getUserPatchContent(name: "Test User Two", patchedEmail: "test@test")
        let userThree = try await getUserPatchContent(name: "Test User Three", patchedEmail: "@test.com")
        let userFour = try await getUserPatchContent(name: "Test User Four", patchedEmail: "test.com")
        
        try app
            .describe("Patch user without valid email should fail")
            .patch(usersPath.appending(userOne.model.requireID().uuidString))
            .body(userOne.patchContent)
            .bearerToken(userOne.token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Patch user without valid email should fail")
            .patch(usersPath.appending(userTwo.model.requireID().uuidString))
            .body(userTwo.patchContent)
            .bearerToken(userTwo.token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Patch user without valid email should fail")
            .patch(usersPath.appending(userThree.model.requireID().uuidString))
            .body(userThree.patchContent)
            .bearerToken(userThree.token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Patch user without valid email should fail")
            .patch(usersPath.appending(userFour.model.requireID().uuidString))
            .body(userFour.patchContent)
            .bearerToken(userFour.token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchUserWithWrongPayloadFails() async throws {
        let (user, token, _) = try await getUserPatchContent()
        
        try app
            .describe("Updating a user with wrong payload returns ok since required payload is optional")
            .patch(usersPath.appending(user.requireID().uuidString))
            .body(["wrong input": "Test Category"])
            .bearerToken(token)
            .expect(.ok)
            .test()
        
        try app
            .describe("User should not have changed")
            .get(usersPath.appending(user.requireID().uuidString))
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
}
