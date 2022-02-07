//
//  UserApiUpdateTests.swift
//  
//
//  Created by niklhut on 24.05.20.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.Update: Content {}

final class UserApiUpdateTests: AppTestCase {
    let usersPath = "api/\(User.pathKey)/\(User.Account.pathKey)/"
    
    private func getUserUpdateContent(
        name: String = "New Test User",
        updatedName: String = "Updated Test User",
        email: String = "new-test-user\(UUID())@example.com",
        updatedEmail: String = "another-test-user\(UUID())@example.com",
        school: String? = nil,
        updatedSchool: String? = nil
    ) async throws -> (model: UserAccountModel, token: String, updateContent: User.Account.Update) {
        let password = "password7293"
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: false, isModerator: false)
        try await user.create(on: app.db)

        let token = try user.generateToken()
        try await token.save(on: app.db)
        
        let updatedUser = User.Account.Update(name: updatedName, email: updatedEmail, school: updatedSchool)
        return (user, token.value, updatedUser)
    }
    
    func testSuccessfulUpdateUserWithSchoolFromNilToValue() async throws {
        let (user, token, updateContent) = try await getUserUpdateContent(updatedSchool: "My School")
        XCTAssertNil(user.school)
        XCTAssertNotNil(updateContent.school)
        
        try app
            .describe("Update user should return ok")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, updateContent.name)
                XCTAssertEqual(content.email, updateContent.email)
                XCTAssertEqual(content.school, updateContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.isModerator, user.isModerator)
        }
        .test()
    }
    
    func testSuccessfulUpdateUserWithSchoolFromValueToValue() async throws {
        let (user, token, updateContent) = try await getUserUpdateContent(school: "My old school", updatedSchool: "My School")
        XCTAssertNotNil(user.school)
        XCTAssertNotNil(updateContent.school)
        
        try app
            .describe("Update user should return ok")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, updateContent.name)
                XCTAssertEqual(content.email, updateContent.email)
                XCTAssertEqual(content.school, updateContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.isModerator, user.isModerator)
        }
        .test()
    }
    
    func testSuccessfulUpdateUserWithSchoolFromValueToNil() async throws {
        let (user, token, updateContent) = try await getUserUpdateContent(school: "My School")
        XCTAssertNotNil(user.school)
        XCTAssertNil(updateContent.school)
        
        try app
            .describe("Update user should return ok")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, updateContent.name)
                XCTAssertEqual(content.email, updateContent.email)
                XCTAssertEqual(content.school, updateContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.isModerator, user.isModerator)
        }
        .test()
    }
    
    func testSuccessfulUpdateUserFromDifferentAdminUser() async throws {
        let (user, _, updateContent) = try await getUserUpdateContent()
        let adminToken = try await getTokenFromOtherAdminUser()
        
        try app
            .describe("Update user from other admin user should return ok")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id)
                XCTAssertEqual(content.name, updateContent.name)
                XCTAssertNil(content.email)
                XCTAssertEqual(content.school, updateContent.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.isModerator, user.isModerator)
            }
            .test()
    }
    
    func testUpdateUserFromDifferentUserFails() async throws {
        let (user, _, updateContent) = try await getUserUpdateContent()
        let token = try await getTokenFromOtherUser()
        
        try app
            .describe("Update user from other non admin user should fail")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateUserWithoutTokenFails() async throws {
        let (user, _, updateContent) = try await getUserUpdateContent()
        
        try app
            .describe("Update user without bearer token fails")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateUserNeedsValidName() async throws {
        let (user, token, updateContent) = try await getUserUpdateContent(updatedName: "")
        
        try app
            .describe("Update user without valid name should fail")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateUserNeedsValidEmail() async throws {
        let userOne = try await getUserUpdateContent(name: "Test User One", updatedEmail:  "")
        let userTwo = try await getUserUpdateContent(name: "Test User Two", updatedEmail: "test@test")
        let userThree = try await getUserUpdateContent(name: "Test User Three", updatedEmail: "@test.com")
        let userFour = try await getUserUpdateContent(name: "Test User Four", updatedEmail: "test.com")

        try app
            .describe("Update user without valid email should fail")
            .put(usersPath.appending(userOne.model.requireID().uuidString))
            .body(userOne.updateContent)
            .bearerToken(userOne.token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Update user without valid email should fail")
            .put(usersPath.appending(userTwo.model.requireID().uuidString))
            .body(userTwo.updateContent)
            .bearerToken(userTwo.token)
            .expect(.badRequest)
            .test()

        try app
            .describe("Update user without valid email should fail")
            .put(usersPath.appending(userThree.model.requireID().uuidString))
            .body(userThree.updateContent)
            .bearerToken(userThree.token)
            .expect(.badRequest)
            .test()

        try app
            .describe("Update user without valid email should fail")
            .put(usersPath.appending(userFour.model.requireID().uuidString))
            .body(userFour.updateContent)
            .bearerToken(userFour.token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateUserWithWrongPayloadFails() async throws {
        let (user, token, _) = try await getUserUpdateContent()
        
        try app
            .describe("Updating a user with wrong payload fails")
            .put(usersPath.appending(user.requireID().uuidString))
            .body(["wrong input": "Test Category"])
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}