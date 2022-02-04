//
//  File.swift
//  
//
//  Created by niklhut on 04.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class UserApiGetOwnUserTests: AppTestCase {
    let getOwnUserPath = "/api/\(User.pathKey)/\(User.Account.pathKey)/me"
    
    private func createNewUser(
        name: String = "New Test User",
        email: String = "test-user@example.com",
        school: String? = nil,
        password: String = "password",
        verified: Bool = false,
        isModerator: Bool = false
    ) async throws -> (user: UserAccountModel, token: String) {
        let user = UserAccountModel(name: name, email: email, school: school, password: try app.password.hash(password), verified: verified, isModerator: isModerator)
        try await user.create(on: app.db)
        
        let token = try user.generateToken()
        try await token.create(on: app.db)
        
        return (user, token.value)
    }
    
    func testGetOwnUser() async throws {
        let (user, token) = try await createNewUser()
        
        try app
            .describe("Get own user should return authenticated user")
            .get(getOwnUserPath)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(User.Account.Detail.self) { content in
                XCTAssertEqual(content.id, user.id!)
                XCTAssertEqual(content.name, user.name)
                XCTAssertEqual(content.email, user.email)
                XCTAssertEqual(content.school, user.school)
                XCTAssertEqual(content.verified, user.verified)
                XCTAssertEqual(content.isModerator, user.isModerator)
        }
        .test()
    }
}
