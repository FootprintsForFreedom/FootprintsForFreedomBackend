//
//  WaypointApiDeleteTagTests.swift
//  
//
//  Created by niklhut on 31.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiDeleteTagTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulDeleteTagOnWaypoint() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        try await waypoint.detail.$language.load(on: app.db)
        
        let tagPivot = try await waypoint.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == waypoint.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Delete tag on waypoint should succeed and return the waypoint without the tag")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.repository.id)
                XCTAssertEqual(content.title, waypoint.detail.title)
                XCTAssertEqual(content.detailText, waypoint.detail.detailText)
                XCTAssertEqual(content.location, waypoint.location.location)
                XCTAssertEqual(content.languageCode, waypoint.detail.language.languageCode)
                XCTAssert(!content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNil(content.detailStatus)
                XCTAssertNil(content.locationStatus)
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }
    
    func testDeleteTagOnWaypointAsUserFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Delete tag on waypoint as user should fail")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteTagOnWaypointWithoutTokenFails() async throws {
        let tag = try await createNewTag(status: .verified)
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Delete tag on waypoint wihtout token should fail")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteTagOnWaypointNeedsValidWaypointId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        
        try app
            .describe("Delete tag on waypoint required valid waypoint id")
            .delete(waypointsPath.appending("\(UUID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDeleteTagOnWaypointNeedsValidTagId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Delete tag on waypoint rqeuires valid tag id")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(UUID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
