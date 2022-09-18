//
//  WaypointApiRequestDeleteTagTests.swift
//  
//
//  Created by niklhut on 31.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiRequestDeleteTagTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulRequestDeleteTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
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
            .describe("Request delete tag on waypoint should succeed and return the waypoint")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.repository.id)
                XCTAssertEqual(content.title, waypoint.detail.title)
                XCTAssertEqual(content.detailText, waypoint.detail.detailText)
                XCTAssertEqual(content.location, waypoint.location.location)
                XCTAssertEqual(content.languageCode, waypoint.detail.language.languageCode)
                XCTAssert(content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }
    
    func testRequestDeleteTagAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Request delete tag on waypoint as unverified user should fail")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testRequestDeleteTagWithoutTokenFails() async throws {
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Request delete tag on waypoint without token should fail")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testRequestDeleteTagOnlyWorksWithVerifiedTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        try await waypoint.detail.$language.load(on: app.db)
        
        let tagPivot = try await waypoint.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == waypoint.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Request delete tag should only work with verified tag")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testRequestDeleteTagNeedsValidWaypointId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
        
        try app
            .describe("Request delete tag on waypoint required valid waypoint id")
            .delete(waypointsPath.appending("\(UUID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.notFound)
            .test()
    }
    
    func testRequestDeleteTagNeedsValidTagId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Request delete tag on waypoint requires valid tag id")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(UUID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testRequestDeleteTagNeedsConnectedTagAndWaypoint() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Request delete tag on waypoint requires connected tag and waypoint")
            .delete(waypointsPath.appending("\(waypoint.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
