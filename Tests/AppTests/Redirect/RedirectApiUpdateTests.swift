//
//  RedirectApiUpdateTests.swift
//  
//
//  Created by niklhut on 22.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class RedirectApiUpdateTests: AppTestCase, RedirectTest {
    private func getRedirectUpdateContent(
        source: String = "this/is/source/\(UUID())",
        updatedSource: String = "some/new/source/\(UUID())",
        destination: String = "and/it/goes/to/\(UUID())",
        updatedDestination: String = "a/different/destination/\(UUID())"
    ) async throws -> (redirect: RedirectModel, updateContent: Redirect.Detail.Update) {
        let redirect = try await createNewRedirect(source: source, destination: destination)
        let updateContent = Redirect.Detail.Update(source: updatedSource, destination: updatedDestination)
        return (redirect, updateContent)
    }
    
    func testSuccessfulUpdateRedirectAsAdmin() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect, updateContent) = try await getRedirectUpdateContent()
        try app
            .describe("Update redirect as admin should return ok")
            .put(redirectPath.appending(redirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.destination, updateContent.destination)
            }
            .test()
        
        let (redirect2, updateContent2) = try await getRedirectUpdateContent(updatedSource: "hello\n\(UUID())")
        try app
            .describe("Update redirect as admin should return ok")
            .put(redirectPath.appending(redirect2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, updateContent2.source)
                XCTAssertEqual(content.destination, updateContent2.destination)
            }
            .test()
        
        let (redirect3, updateContent3) = try await getRedirectUpdateContent(updatedSource: "hello, it is me here! & you \(UUID())")
        try app
            .describe("Update redirect as admin should return ok")
            .put(redirectPath.appending(redirect3.requireID().uuidString))
            .body(updateContent3)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, updateContent3.source)
                XCTAssertEqual(content.destination, updateContent3.destination)
            }
            .test()
        
        let source4 = "some/source/\(UUID())"
        let destination4 = "some/destination/\(UUID())"
        let (redirect4, updateContent4) = try await getRedirectUpdateContent(source: source4, updatedSource: source4, destination: destination4, updatedDestination: destination4)
        try app
            .describe("Update redirect as admin should return ok")
            .put(redirectPath.appending(redirect4.requireID().uuidString))
            .body(updateContent4)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, updateContent4.source)
                XCTAssertEqual(content.destination, updateContent4.destination)
            }
            .test()
    }
    
    func testSuccessfulUpdateRedirectWithDuplicateDestination() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, updateContent) = try await getRedirectUpdateContent(updatedDestination: redirect.destination)
        
        try app
            .describe("Update redirect with duplicate destination should return ok")
            .put(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.destination, updateContent.destination)
            }
            .test()
    }
    
    func testSuccessfulUpdateRedirectRemovesLeadingAndTrailingSlashes() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (redirect, updateContent) = try await getRedirectUpdateContent(updatedSource: "/Hello/this/is/\(UUID())/", updatedDestination: "/And/it/goes/to/\(UUID())/")
        
        try app
            .describe("Update redirect with leading and/or trailing slashes should remove them")
            .put(redirectPath.appending(redirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, updateContent.source.split(separator: "?").first?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))))
                XCTAssertEqual(content.destination, updateContent.destination.split(separator: "?").first?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))))
            }
            .test()
    }
    
    func testUpdateRedirectWithDuplicateSourceFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, updateContent) = try await getRedirectUpdateContent(updatedSource: redirect.source)
        
        try app
            .describe("Update redirect with duplicate source should fail")
            .put(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateRedirectWithSameSourceAndDestinationFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let string = "this/is/a/test"
        let (redirect, updateContent) = try await getRedirectUpdateContent(updatedSource: string, updatedDestination: string)
        
        try app
            .describe("Update redirect with same source and destination should fail")
            .put(redirectPath.appending(redirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateRedirectWithSourceAsOtherRedirectsDestinationFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, updateContent) = try await getRedirectUpdateContent(updatedSource: redirect.destination)
        
        try app
            .describe("Update redirect with source existing as other redirect's destination should fail")
            .put(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateRedirectWithDestinationAsOtherRedirectsSourceFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, updateContent) = try await getRedirectUpdateContent(updatedDestination: redirect.source)
        
        try app
            .describe("Update redirect with destination existing as other redirect's source should fail")
            .put(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateRedirectAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator, verified: true)
        let (redirect, updateContent) = try await getRedirectUpdateContent()
        
        try app
            .describe("Update redirect as moderator should should fail")
            .put(redirectPath.appending(redirect.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateRedirectWithoutTokenFails() async throws {
        let (redirect, updateContent) = try await getRedirectUpdateContent()
        
        try app
            .describe("Update redirect without token should fail")
            .put(redirectPath.appending(redirect.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateRedirectNeedsValidSource() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect1, updateContent1) = try await getRedirectUpdateContent(updatedSource: "")
        try app
            .describe("Update redirect with empty source should fail")
            .put(redirectPath.appending(redirect1.requireID().uuidString))
            .body(updateContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect2, updateContent2) = try await getRedirectUpdateContent(updatedSource: "?hello=\(UUID())")
        try app
            .describe("Update redirect with query instead of path should fail")
            .put(redirectPath.appending(redirect2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect3, updateContent3) = try await getRedirectUpdateContent(updatedSource: " \n\t ")
        try app
            .describe("Update redirect with whitespace should fail")
            .put(redirectPath.appending(redirect3.requireID().uuidString))
            .body(updateContent3)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect4, updateContent4) = try await getRedirectUpdateContent(updatedSource: "/")
        try app
            .describe("Update redirect with empty source should fail")
            .put(redirectPath.appending(redirect4.requireID().uuidString))
            .body(updateContent4)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateRedirectNeedsValidDestination() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect1, updateContent1) = try await getRedirectUpdateContent(updatedDestination: "")
        try app
            .describe("Update redirect with empty source should fail")
            .put(redirectPath.appending(redirect1.requireID().uuidString))
            .body(updateContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect2, updateContent2) = try await getRedirectUpdateContent(updatedDestination: "?hello=\(UUID())")
        try app
            .describe("Update redirect with query instead of path should fail")
            .put(redirectPath.appending(redirect2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect3, updateContent3) = try await getRedirectUpdateContent(updatedDestination: " \n\t ")
        try app
            .describe("Update redirect with whitespace should fail")
            .put(redirectPath.appending(redirect3.requireID().uuidString))
            .body(updateContent3)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect4, updateContent4) = try await getRedirectUpdateContent(updatedDestination: "/")
        try app
            .describe("Update redirect with empty source should fail")
            .put(redirectPath.appending(redirect4.requireID().uuidString))
            .body(updateContent4)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
