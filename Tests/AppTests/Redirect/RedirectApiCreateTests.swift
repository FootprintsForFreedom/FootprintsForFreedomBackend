//
//  RedirectApiCreateTests.swift
//  
//
//  Created by niklhut on 17.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Redirect.Detail.Create: Content { }

final class RedirectApiCreateTests: AppTestCase, RedirectTest {
    private func getRedirectCreateContent(
        source: String = "this/is/source/\(UUID())",
        destination: String = "and/it/goes/to/\(UUID())"
    ) async throws -> Redirect.Detail.Create {
        .init(source: source, destination: destination)
    }
    
    func testSuccessfulCreateRedirectAsAdmin() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let newRedirect = try await getRedirectCreateContent()
        try app
            .describe("Create redirect as admin should return ok")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.created)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, newRedirect.source)
                XCTAssertEqual(content.destination, newRedirect.destination)
            }
            .test()
        
        let newRedirect2 = try await getRedirectCreateContent(source: "hello\n\(UUID())")
        try app
            .describe("Create redirect as admin should return ok")
            .post(redirectPath)
            .body(newRedirect2)
            .bearerToken(token)
            .expect(.created)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, newRedirect2.source)
                XCTAssertEqual(content.destination, newRedirect2.destination)
            }
            .test()
        
        let newRedirect3 = try await getRedirectCreateContent(source: "hello, it is me here! & you \(UUID())")
        try app
            .describe("Create redirect as admin should return ok")
            .post(redirectPath)
            .body(newRedirect3)
            .bearerToken(token)
            .expect(.created)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, newRedirect3.source)
                XCTAssertEqual(content.destination, newRedirect3.destination)
            }
            .test()
    }
    
    func testSuccessfulCreateRedirectWithDuplicateDestination() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let newRedirect = try await getRedirectCreateContent(destination: redirect.destination)
        
        try app
            .describe("Create redirect with duplicate destination should return ok")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.created)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, newRedirect.source)
                XCTAssertEqual(content.destination, newRedirect.destination)
            }
            .test()
    }
    
    func testSuccessfulCreateRedirectRemovesLeadingAndTrailingSlashes() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await getRedirectCreateContent(source: "/Hello/this/is/\(UUID())/", destination: "/And/it/goes/to/\(UUID())/")
        
        try app
            .describe("Create redirect with leading and/or trailing slashes should remove them")
            .post(redirectPath)
            .body(redirect)
            .bearerToken(token)
            .expect(.created)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, redirect.source.split(separator: "?").first?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))))
                XCTAssertEqual(content.destination, redirect.destination.split(separator: "?").first?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))))
            }
            .test()
    }
    
    func testCreateRedirectWithDuplicateSourceFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let newRedirect = try await getRedirectCreateContent(source: redirect.source)
        
        try app
            .describe("Create redirect with duplicate source should fail")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateRedirectWithSameSourceAndDestinationFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let string = "this/is/a/test"
        let redirect = try await getRedirectCreateContent(source: string, destination: string)
        
        try app
            .describe("Create redirect with same source and destination should fail")
            .post(redirectPath)
            .body(redirect)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateRedirectWithSourceAsOtherRedirectsDestinationFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let newRedirect = try await getRedirectCreateContent(source: redirect.destination)
        
        try app
            .describe("Create redirect with source existing as other redirect's destination should fail")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateRedirectWithDestinationAsOtherRedirectsSourceFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let newRedirect = try await getRedirectCreateContent(destination: redirect.source)
        
        try app
            .describe("Create redirect with destination existing as other redirect's source should fail")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.badRequest)
            .test()

    }
    
    func testCreateRedirectAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator, verified: true)
        let newRedirect = try await getRedirectCreateContent()
        
        try app
            .describe("Create redirect as moderator should should fail")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateRedirectWithoutTokenFails() async throws {
        let newRedirect = try await getRedirectCreateContent()
        
        try app
            .describe("Create redirect without token should fail")
            .post(redirectPath)
            .body(newRedirect)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateRedirectNeedsValidSource() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let newRedirect = try await getRedirectCreateContent(source: "")
        try app
            .describe("Create redirect with empty source should fail")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newRedirect2 = try await getRedirectCreateContent(source: "?hello=\(UUID())")
        try app
            .describe("Create redirect with query instead of path should fail")
            .post(redirectPath)
            .body(newRedirect2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newRedirect3 = try await getRedirectCreateContent(source: " \n\t ")
        try app
            .describe("Create redirect with whitespace should fail")
            .post(redirectPath)
            .body(newRedirect3)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newRedirect4 = try await getRedirectCreateContent(source: "/")
        try app
            .describe("Create redirect with empty source should fail")
            .post(redirectPath)
            .body(newRedirect4)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateRedirectNeedsValidDestination() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let newRedirect = try await getRedirectCreateContent(destination: "")
        try app
            .describe("Create redirect with empty destination should fail")
            .post(redirectPath)
            .body(newRedirect)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newRedirect2 = try await getRedirectCreateContent(destination: "?hello=\(UUID())")
        try app
            .describe("Create redirect with query instead of path should fail")
            .post(redirectPath)
            .body(newRedirect2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newRedirect3 = try await getRedirectCreateContent(destination: " \n\t ")
        try app
            .describe("Create redirect with whitespace should fail")
            .post(redirectPath)
            .body(newRedirect3)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newRedirect4 = try await getRedirectCreateContent(destination: "/")
        try app
            .describe("Create redirect with empty destination should fail")
            .post(redirectPath)
            .body(newRedirect4)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
