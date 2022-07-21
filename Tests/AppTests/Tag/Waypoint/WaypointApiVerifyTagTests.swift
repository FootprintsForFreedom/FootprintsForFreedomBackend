//
//  WaypointApiVerifyTagTests.swift
//  
//
//  Created by niklhut on 31.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiVerifyTagTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulVerifyTagOnWaypoint() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.repository.id)
                XCTAssertEqual(content.title, waypoint.detail.title)
                XCTAssertEqual(content.detailText, waypoint.detail.detailText)
                XCTAssertEqual(content.location, waypoint.location.location)
                XCTAssertEqual(content.languageCode, waypoint.detail.language.languageCode)
                XCTAssert(content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNil(content.detailStatus)
                XCTAssertNil(content.locationStatus)
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }
    
    func testVerifyTagOnWaypointAsUserFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on waypoint as user should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyTagOnWaypointWithoutTokenFails() async throws {
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on waypoint without token should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyTagOnWaypointNeedsValidWaypointId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        
        try app
            .describe("Verify tag on waypoint required valid waypoint id")
            .post(waypointsPath.appending("\(UUID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testVerifyTagOnWaypointNeedsValidTagId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Verify tag on waypoint requires valid tag id")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(UUID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testVerifyTagOnWaypointNeedsConnectedTagAndWaypoint() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Verify tag on waypoint requires connected tag and waypoint")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testVerifyTagOnWaypointWithAlreadyVerifiedTagFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        let tagPivot = try await waypoint.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == waypoint.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify tag on waypoint with already verified tag should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()

    }
}
