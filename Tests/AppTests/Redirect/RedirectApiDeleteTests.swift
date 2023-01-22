//
//  RedirectApiDeleteTests.swift
//  
//
//  Created by niklhut on 22.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class RedirectApiDeleteTests: AppTestCase, RedirectTest {
    func testSuccessfulDeleteUnverifiedRedirectAsAdmin() async throws {
        // Get original redirect count
        let redirectCount = try await RedirectModel.query(on: app.db).count()
        
        let redirect = try await createNewRedirect()
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("An admin should be able to delete an unverified redirect")
            .delete(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.noContent)
            .test()
        
        // New redirect count should be original redirect count
        let newRedirectCount = try await RedirectModel.query(on: app.db).count()
        XCTAssertEqual(newRedirectCount, redirectCount)
    }
    
    func testSuccessfulDeleteVerifiedRedirectAsAdmin() async throws {
        // Get original redirect count
        let redirectCount = try await RedirectModel.query(on: app.db).count()
        
        let redirect = try await createNewRedirect()
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("An admin should be able to delete an unverified redirect")
            .delete(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.noContent)
            .test()
        
        // New redirect count should be original redirect count
        let newRedirectCount = try await RedirectModel.query(on: app.db).count()
        XCTAssertEqual(newRedirectCount, redirectCount)
    }
    
    func testDeleteRedirectRepositoryDeletesDetails() async throws {
        // Get original redirect count
        let redirectCount = try await RedirectModel.query(on: app.db).count()
        
        let redirect = try await createNewRedirect()
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("An admin should be able to delete an unverified redirect")
            .delete(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.noContent)
            .test()
        
        // New redirect count should be original redirect count
        let newRedirectCount = try await RedirectModel.query(on: app.db).count()
        XCTAssertEqual(newRedirectCount, redirectCount)
    }
    
    func testDeleteUnverifiedRedirectAsCreatorFails() async throws {
        let user = try await getUser(role: .user)
        let userToken = try user.generateToken()
        try await userToken.create(on: app.db)
        let redirect = try await createNewRedirect()
        
        try app
            .describe("A user should not be able to delete a redirect")
            .delete(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(userToken.value)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteUnverifiedRedirectAsUserFails() async throws {
        let redirect = try await createNewRedirect()
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("A user should not be able to delete a redirect")
            .delete(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteRedirectWithoutTokenFails() async throws {
        let redirect = try await createNewRedirect()
        
        try app
            .describe("Delete redirect without token fails")
            .delete(redirectPath.appending(redirect.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingRedirectFails() async throws {
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("Delete nonexistent redirect fails")
            .delete(redirectPath.appending(UUID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }
}

