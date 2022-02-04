//
//  UserApiLoginTests.swift
//  
//
//  Created by niklhut on 03.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class UserApiLoginTests: AppTestCase {
    let signInPath = "/api/sign-in/"
    
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-user@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        isModerator: Bool = false
    ) async throws -> (UserAccountModel, String) {
        let user = UserAccountModel(name: name, email: email, school: school, password: try Bcrypt.hash(password), verified: verified, isModerator: isModerator)
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
                XCTAssert(!content.value.isEmpty)
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
    
//    func testLoginDeltesOldTokens() async throws {
//        let (user, password) = try await createNewUser()
//
//        let token = try user.generateToken()
//        try token.create(on: app.db).wait()
//
//        let credentials = UserLoginRequest(name: user.name, password: password)
//
//        try app
//            .describe("Credentials Login should return ok")
//            .post(signInPath)
//            .body(credentials)
//            .expect(.ok)
//            .expect(.json)
//            .test()
//
//        let tokenCount = try UserTokenModel.query(on: app.db).filter(\.$user.$id, .equal, user.id!).count().wait()
//        XCTAssertEqual(tokenCount, 1)
//    }
}
