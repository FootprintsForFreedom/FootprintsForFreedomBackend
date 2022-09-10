//
//  WaypointApiAddTagTests.swift
//  
//
//  Created by niklhut on 31.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiAddTagTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulAddTagToWaypoint() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Add tag to waypoint should return ok and the waypoint")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.repository.id)
                XCTAssertEqual(content.title, waypoint.detail.title)
                XCTAssertEqual(content.detailText, waypoint.detail.detailText)
                XCTAssertEqual(content.location, waypoint.location.location)
                XCTAssertEqual(content.languageCode, waypoint.detail.language.languageCode)
                XCTAssert(!content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }
    
    func testAddTagToWaypointAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Add tag to waypoint as unverified user should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testAddTagToWaypointsWithoutTokenFails() async throws {
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Add tag to waypoint requires verified tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testAddTagToWaypointsNeedsValidWaypointId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
        
        try app
            .describe("Add tag to waypoint requires valid (but not necessarily verified) waypoint id")
            .post(waypointsPath.appending("\(UUID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.notFound)
            .test()
    }
    
    func testAddTagToWaypointsNeedsVerifiedTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Add tag to waypoint requires verified tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
