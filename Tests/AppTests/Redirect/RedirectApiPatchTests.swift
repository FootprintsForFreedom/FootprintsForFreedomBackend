//
//  RedirectApiPatchTests.swift
//  
//
//  Created by niklhut on 22.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Redirect.Detail.Patch: Content { }

final class RedirectApiPatchTests: AppTestCase, RedirectTest {
    private func getRedirectPatchContent(
        source: String = "this/is/source/\(UUID())",
        patchedSource: String? = nil,
        destination: String = "and/it/goes/to/\(UUID())",
        patchedDestination: String? = nil
    ) async throws -> (redirect: RedirectModel, patchContent: Redirect.Detail.Patch) {
        let redirect = try await createNewRedirect(source: source, destination: destination)
        let patchContent = Redirect.Detail.Patch(source: patchedSource, destination: patchedDestination)
        return (redirect, patchContent)
    }
    
    func testSuccessfulPatchRedirectSourceAsAdmin() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect, patchContent) = try await getRedirectPatchContent(patchedSource: "this/is/patched/source/\(UUID())")
        try app
            .describe("Patch redirect as admin should return ok")
            .patch(redirectPath.appending(redirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, patchContent.source)
                XCTAssertEqual(content.destination, redirect.destination)
            }
            .test()
        
        let (redirect2, patchContent2) = try await getRedirectPatchContent(patchedSource: "hello\n\(UUID())")
        try app
            .describe("Patch redirect as admin should return ok")
            .patch(redirectPath.appending(redirect2.requireID().uuidString))
            .body(patchContent2)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, patchContent2.source)
                XCTAssertEqual(content.destination, redirect2.destination)
            }
            .test()
        
        let (redirect3, patchContent3) = try await getRedirectPatchContent(patchedSource: "hello, it is me here! & you \(UUID())")
        try app
            .describe("Patch redirect as admin should return ok")
            .patch(redirectPath.appending(redirect3.requireID().uuidString))
            .body(patchContent3)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, patchContent3.source)
                XCTAssertEqual(content.destination, redirect3.destination)
            }
            .test()
    }
    
    func testSuccessfulPatchRedirectDestinationAsAdmin() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect, patchContent) = try await getRedirectPatchContent(patchedDestination: "this/is/patched/source/\(UUID())")
        try app
            .describe("Patch redirect as admin should return ok")
            .patch(redirectPath.appending(redirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, redirect.source)
                XCTAssertEqual(content.destination, patchContent.destination)
            }
            .test()
        
        let (redirect2, patchContent2) = try await getRedirectPatchContent(patchedDestination: "hello\n\(UUID())")
        try app
            .describe("Patch redirect as admin should return ok")
            .patch(redirectPath.appending(redirect2.requireID().uuidString))
            .body(patchContent2)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, redirect2.source)
                XCTAssertEqual(content.destination, patchContent2.destination)
            }
            .test()
        
        let (redirect3, patchContent3) = try await getRedirectPatchContent(patchedDestination: "hello, it is me here! & you \(UUID())")
        try app
            .describe("Patch redirect as admin should return ok")
            .patch(redirectPath.appending(redirect3.requireID().uuidString))
            .body(patchContent3)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, redirect3.source)
                XCTAssertEqual(content.destination, patchContent3.destination)
            }
            .test()
    }
    
    func testSuccessfulPatchRedirectWithDuplicateDestination() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, patchContent) = try await getRedirectPatchContent(patchedDestination: redirect.destination)
        
        try app
            .describe("Patch redirect with duplicate destination should return ok")
            .patch(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, newRedirect.source)
                XCTAssertEqual(content.destination, patchContent.destination)
            }
            .test()
    }
    
    func testSuccessfulPatchRedirectRemovesLeadingAndTrailingSlashes() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (redirect, patchContent) = try await getRedirectPatchContent(patchedSource: "/Hello/this/is/\(UUID())/", patchedDestination: "/And/it/goes/to/\(UUID())/")
        
        try app
            .describe("Patch redirect with leading and/or trailing slashes should remove them")
            .patch(redirectPath.appending(redirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(Redirect.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.source, patchContent.source!.split(separator: "?").first?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))))
                XCTAssertEqual(content.destination, patchContent.destination!.split(separator: "?").first?.trimmingCharacters(in: .whitespacesAndNewlines.union(.init(charactersIn: "/"))))
            }
            .test()
    }
    
    func testPatchRedirectWithDuplicateSourceFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, patchContent) = try await getRedirectPatchContent(patchedSource: redirect.source)
        
        try app
            .describe("Patch redirect with duplicate source should fail")
            .patch(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchRedirectWithSameSourceAndDestinationFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let string = "this/is/a/test"
        let (redirect, patchContent) = try await getRedirectPatchContent(patchedSource: string, patchedDestination: string)
        
        try app
            .describe("Patch redirect with same source and destination should fail")
            .patch(redirectPath.appending(redirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchRedirectWithSourceAsOtherRedirectsDestinationFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, patchContent) = try await getRedirectPatchContent(patchedSource: redirect.destination)
        
        try app
            .describe("Patch redirect with source existing as other redirect's destination should fail")
            .patch(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchRedirectWithDestinationAsOtherRedirectsSourceFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let redirect = try await createNewRedirect()
        let (newRedirect, patchContent) = try await getRedirectPatchContent(patchedDestination: redirect.source)
        
        try app
            .describe("Patch redirect with destination existing as other redirect's source should fail")
            .patch(redirectPath.appending(newRedirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchRedirectAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator, verified: true)
        let (redirect, patchContent) = try await getRedirectPatchContent()
        
        try app
            .describe("Patch redirect as moderator should should fail")
            .patch(redirectPath.appending(redirect.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchRedirectWithoutTokenFails() async throws {
        let (redirect, patchContent) = try await getRedirectPatchContent()
        
        try app
            .describe("Patch redirect without token should fail")
            .patch(redirectPath.appending(redirect.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testPatchRedirectNeedsValidSource() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect1, patchContent1) = try await getRedirectPatchContent(patchedSource: "")
        try app
            .describe("Patch redirect with empty source should fail")
            .patch(redirectPath.appending(redirect1.requireID().uuidString))
            .body(patchContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect2, patchContent2) = try await getRedirectPatchContent(patchedSource: "?hello=\(UUID())")
        try app
            .describe("Patch redirect with query instead of path should fail")
            .patch(redirectPath.appending(redirect2.requireID().uuidString))
            .body(patchContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect3, patchContent3) = try await getRedirectPatchContent(patchedSource: " \n\t ")
        try app
            .describe("Patch redirect with whitespace should fail")
            .patch(redirectPath.appending(redirect3.requireID().uuidString))
            .body(patchContent3)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect4, patchContent4) = try await getRedirectPatchContent(patchedSource: "/")
        try app
            .describe("Patch redirect with empty source should fail")
            .patch(redirectPath.appending(redirect4.requireID().uuidString))
            .body(patchContent4)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchRedirectNeedsValidDestination() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        let (redirect1, patchContent1) = try await getRedirectPatchContent(patchedDestination: "")
        try app
            .describe("Patch redirect with empty source should fail")
            .patch(redirectPath.appending(redirect1.requireID().uuidString))
            .body(patchContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect2, patchContent2) = try await getRedirectPatchContent(patchedDestination: "?hello=\(UUID())")
        try app
            .describe("Patch redirect with query instead of path should fail")
            .patch(redirectPath.appending(redirect2.requireID().uuidString))
            .body(patchContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect3, patchContent3) = try await getRedirectPatchContent(patchedDestination: " \n\t ")
        try app
            .describe("Patch redirect with whitespace should fail")
            .patch(redirectPath.appending(redirect3.requireID().uuidString))
            .body(patchContent3)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let (redirect4, patchContent4) = try await getRedirectPatchContent(patchedDestination: "/")
        try app
            .describe("Patch redirect with empty source should fail")
            .patch(redirectPath.appending(redirect4.requireID().uuidString))
            .body(patchContent4)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
