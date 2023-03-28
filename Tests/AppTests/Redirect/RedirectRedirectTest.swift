//
//  RedirectRedirectTest.swift
//  
//
//  Created by niklhut on 22.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class RedirectRedirectTest: AppTestCase, RedirectTest {
    func testSuccessfulRedirect() async throws {
        let redirect = try await createNewRedirect()
        
        try app
            .describe("Get valid redirect redirects successfully")
            .get(redirect.source)
            .expect(.movedPermanently)
            .test()
    }
    
    func testSuccessfulRedirectRetainsQuery() async throws {
        let redirect = try await createNewRedirect()
        let query = "?hello=thisQuery&some=thing"
        
        try app
            .describe("Get valid redirect redirects and retains query")
            .get(redirect.source.appending(query))
            .expect(.movedPermanently)
            .expect("location", [redirect.destination.appending(query)])
            .test()
    }
    
    func testSuccessfulRequestUnavailableResource() async throws {
        try app
            .describe("Get unavailable path fails")
            .get("/this/path/does/not/exist/\(UUID())")
            .expect(.internalServerError)
            .test()
    }
}
