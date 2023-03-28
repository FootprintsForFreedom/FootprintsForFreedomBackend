//
//  UserApiSignOutTests.swift
//  
//
//  Created by niklhut on 04.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class UserApiSignOutTests: AppTestCase {
    let signOutPath = "/api/v1/sign-out/"
    
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-user\(UUID())@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        role: User.Role = .user
    ) async throws -> (user: UserAccountModel, token: String) {
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: verified, role: role)
        try await user.create(on: app.db)
        
        let token = try user.generateToken()
        try await token.create(on: app.db)
        
        return (user, token.value)
    }
    
    func testSuccessfulSignOut() async throws {
        let (_, token) = try await createNewUser()
        
        try app
            .describe("When user signs out the token he used is deleted")
            .post(signOutPath)
            .bearerToken(token)
            .expect(.ok)
            .test()
        
        let tokensByValue = try await UserTokenModel.query(on: app.db).filter(\.$value, .equal, token).count()
        XCTAssertEqual(tokensByValue, 0)
    }
}
