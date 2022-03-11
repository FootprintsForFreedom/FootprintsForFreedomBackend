//
//  UserApiSignInTests.swift
//  
//
//  Created by niklhut on 03.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class UserApiSignInTests: AppTestCase {
    let signInPath = "/api/sign-in/"
    
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-user\(UUID())@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> (user: UserAccountModel, password: String) {
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: verified, role: role)
        try await user.create(on: app.db)
        
        return (user, password)
    }
    
    func testSuccessfulLogin() async throws {
        let (user, password) = try await createNewUser()
        
        let credentials = UserLogin(email: user.email, password: password)
        
        try app
            .describe("Credentials login should return ok")
            .post(signInPath)
            .body(credentials)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.value.count, 64)
                XCTAssertEqual(content.user.email, user.email)
            }
            .test()
    }
    
    func testLoginWithNonExistingUserFails() throws {
        let credentials = UserLogin(email: "thisemail.doesntexist@example.com", password: "123")
        
        try app
            .describe("Credentials Login with non existing user should fail")
            .post(signInPath)
            .body(credentials)
            .expect(.unauthorized)
            .test()
    }
    
    func testLoginWithIncorrectPasswordFails() async throws {
        let (user, _) = try await createNewUser()
        
        let credentials = UserLogin(email: user.email, password: "wrongPassword")
        
        try app
            .describe("Credentials Login should return ok")
            .post(signInPath)
            .body(credentials)
            .expect(.unauthorized)
            .test()
    }
    
    func testLoginReturnsDifferentTokensForDifferentUser() async throws {
        let (user1, password1) = try await createNewUser()
        let (user2, password2) = try await createNewUser(email: "test-user.\(UUID())@example.com")
        
        let credentials1 = UserLogin(email: user1.email, password: password1)
        let credentials2 = UserLogin(email: user2.email, password: password2)
        
        var token1: String!
        
        try app
            .describe("First user should login successfully and get token")
            .post(signInPath)
            .body(credentials1)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.value.count, 64)
                token1 = content.value
                XCTAssertEqual(content.user.email, user1.email)
            }
            .test()
        
        try app
            .describe("Second user should login successfully and get different token than user one")
            .post(signInPath)
            .body(credentials2)
            .expect(.ok)
            .expect(.json)
            .expect(User.Token.Detail.self) { content in
                XCTAssertEqual(content.value.count, 64)
                XCTAssertNotEqual(content.value, token1)
                XCTAssertEqual(content.user.email, user2.email)
            }
            .test()
    }
    
}

