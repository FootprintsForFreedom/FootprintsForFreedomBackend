//
//  RedirectApiGetTests.swift
//  
//
//  Created by niklhut on 22.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class RedirectApiGetTests: AppTestCase, RedirectTest {
    
    // MARK: - List
    
    func testSuccessfulListRedirect() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        
        let redirect1 = try await createNewRedirect()
        let redirect2 = try await createNewRedirect()
        
        let redirectCount = try await RedirectModel
            .query(on: app.db)
            .count()
        
        try app
            .describe("List redirect should reurn ok")
            .get(redirectPath.appending("?per=\(redirectCount)"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Redirect.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == redirect1.id! })
                XCTAssert(content.items.contains { $0.id == redirect2.id! })
            }
            .test()
    }
        
    func testListRedirectAsModeratorFails() async throws {
        let moderatorToken = try await getToken(for: .moderator, verified: true)
        
        try app
            .describe("List redirect as moderator should fail")
            .get(redirectPath)
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListRedirectWithoutTokenFails() async throws {
        try app
            .describe("List redirect without token should fail")
            .get(redirectPath)
            .expect(.unauthorized)
            .test()
    }
    
    // MARK: - Get
    
    func testSuccessfulGetRedirectByIdAsAdmin() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        
        try app
            .describe("Get redirect by id should return ok")
            .get(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, redirect.id)
                XCTAssertEqual(content.source, redirect.source)
                XCTAssertEqual(content.destination, redirect.destination)
            }
            .test()
    }
    
    func testGetRedirectByIdAsModeratorFails() async throws {
        let redirect = try await createNewRedirect()
        
        try app
            .describe("Get redirect by id as moderator should fail")
            .get(redirectPath.appending(redirect.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .expect(.json)
            .test()
    }
    
    func testGetRedirectByIdWithoutTokenFails() async throws {
        let redirect = try await createNewRedirect()
        
        try app
            .describe("Get redirect by id without token should fail")
            .get(redirectPath.appending(redirect.requireID().uuidString))
            .expect(.unauthorized)
            .expect(.json)
            .test()
    }
}
