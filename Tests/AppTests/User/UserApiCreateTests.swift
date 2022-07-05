//
//  UserApiCreateTests.swift
//  
//
//  Created by niklhut on 23.05.20.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.Create: Content {}

final class UserApiCreateTests: AppTestCase, UserTest {
    private func getUserCreateContent(
        name: String = "New Test User",
        email: String = "new-test-user\(UUID())@example.com",
        school: String? = nil,
        password: String = "new3Password"
    ) throws -> User.Account.Create {
        let user = User.Account.Create(name: name, email: email, school: school, password: password)
        
        return user
    }
    
    func testSuccessfulCreateUser() async throws {
        let newUser = try getUserCreateContent()
        
        // Get original user count
        let userCount = try await UserAccountModel.query(on: app.db).count()
        
        try app
            .describe("Create user should return ok")
            .post(usersPath)
            .body(newUser)
            .expect(.created)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.name, newUser.name)
                XCTAssertEqual(content.email, newUser.email)
                XCTAssertEqual(content.school, newUser.school)
                XCTAssertEqual(content.verified, false)
                XCTAssertEqual(content.role, .user)
        }
        .test()
        
        // New user count should be one more than original user count
        let newUserCount = try await UserAccountModel.query(on: app.db).count()
        XCTAssertEqual(newUserCount, userCount + 1)
    }
    
    func testNewPasswordNeedsAtLeastSixCharacters() async throws {
        let newUser = try getUserCreateContent(password: "1aB")
        
        try app
            .describe("New user password needs at least six characters; Update password fails")
            .post(usersPath)
            .body(newUser)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsUppercasedLetter() async throws {
        let password = "1newpassword"
        let newUser = try getUserCreateContent(password: password)

        try app
            .describe("New user password needs at least one uppercased letter; Update password fails")
            .post(usersPath)
            .body(newUser)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsLowercasedLetter() async throws {
        let password = "1NEWPASSWORD"
        let newUser = try getUserCreateContent(password: password)
        
        try app
            .describe("New user password needs at least one lowercased letter; Update password fails")
            .post(usersPath)
            .body(newUser)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordNeedsDigit() async throws {
        let password = "newPassword"
        let newUser = try getUserCreateContent(password: password)
        
        try app
            .describe("New user password needs at least one digit; Update password fails")
            .post(usersPath)
            .body(newUser)
            .expect(.badRequest)
            .test()
    }
    
    func testNewPasswordWihtNewLineFails() async throws {
        let password = "1new\nPassword"
        let newUser = try getUserCreateContent(password: password)
        
        try app
            .describe("New user password must not contain new line; Update password fails")
            .post(usersPath)
            .body(newUser)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateUserNeedsValidName() throws {
        let newUser = try getUserCreateContent(name: "")

        try app
            .describe("Create user without valid name should fail")
            .post(usersPath)
            .body(newUser)
            .expect(.badRequest)
            .test()
    }

    func testCreateUserNeedsValidEmail() throws {
        let newUserOne = try getUserCreateContent(name: "New Test User One", email: "")
        let newUserTwo = try getUserCreateContent(name: "New Test User Two", email: "test@test")
        let newUserThree = try getUserCreateContent(name: "New Test User Three", email: "@test.com")
        let newUserFour = try getUserCreateContent(name: "New Test User Four", email: "test.com")

        try app
            .describe("Create user without valid email should fail")
            .post(usersPath)
            .body(newUserOne)
            .expect(.badRequest)
            .test()

        try app
            .describe("Create user without valid email should fail")
            .post(usersPath)
            .body(newUserTwo)
            .expect(.badRequest)
            .test()

        try app
            .describe("Create user without valid email should fail")
            .post(usersPath)
            .body(newUserThree)
            .expect(.badRequest)
            .test()

        try app
            .describe("Create user without valid email should fail")
            .post(usersPath)
            .body(newUserFour)
            .expect(.badRequest)
            .test()
    }

    func testCreateUserWithWrongPayloadFails() throws {
        try app
            .describe("Creating a user with wrong payload fails")
            .post(usersPath)
            .body(["wrong input": "Test Category"])
            .expect(.badRequest)
            .test()
    }
    
}
