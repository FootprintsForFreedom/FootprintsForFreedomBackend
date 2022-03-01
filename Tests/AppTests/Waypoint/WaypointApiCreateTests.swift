//
//  WaypointApiCreateTests.swift
//  
//
//  Created by niklhut on 19.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Waypoint.Waypoint.Create: Content { }

final class WaypointApiCreateTests: AppTestCaseWithToken  {
    let waypointsPath = "api/waypoints/"
    
    private func getWaypointCreateContent(
        title: String = "New Waypoint Title",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180))
    ) -> Waypoint.Waypoint.Create {
        .init(title: title, description: description, location: location)
    }
    
    func testSuccessfulCreateWaypoint() async throws {
        let newWaypoint = getWaypointCreateContent()
        
        // Get original waypoint count
        let waypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        
        try app
            .describe("Create waypoint should return ok")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.created)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newWaypoint.title)
                XCTAssertEqual(content.description, newWaypoint.description)
                XCTAssertEqual(content.location, newWaypoint.location)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // New waypoint count should be one more than original waypoint count
        let newWaypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount + 1)
    }
    
    func testCreatedWaypointIsUnverified() async throws {
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        let newWaypoint = getWaypointCreateContent()
        
        // Get original waypoint count
        let waypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        
        try app
            .describe("Create waypoint should return ok")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(moderatorToken)
            .expect(.created)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newWaypoint.title)
                XCTAssertEqual(content.description, newWaypoint.description)
                XCTAssertEqual(content.location, newWaypoint.location)
                XCTAssertEqual(content.verified, false)
            }
            .test()
        
        // New waypoint count should be one more than original waypoint count
        let newWaypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount + 1)
    }
    
    func testCreateWaypointWithoutTokenFails() async throws {
        let newWaypoint = getWaypointCreateContent()
        
        try app
            .describe("Create waypoint without token should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateWaypointNeedsValidTitle() async throws {
        let newWaypoint = getWaypointCreateContent(title: "")
        
        try app
            .describe("Create waypoint with empty title should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsValidDescription() async throws {
        let newWaypoint = getWaypointCreateContent(description: "")
        
        try app
            .describe("Create waypoint with empty description should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsLocation() async throws {
        struct Create: Content {
            let title: String
            let description: String
        }
        let newWaypoint = Create(title: "New Title", description: "New Description")
        
        try app
            .describe("Create waypoint without location should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsValidLatitude() async throws {
        let newWaypoint = getWaypointCreateContent(location: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Create waypoint with too large latitude should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsValidLongitude() async throws {
        let newWaypoint = getWaypointCreateContent(location: .init(latitude: 20, longitude: 181))
        
        try app
            .describe("Create waypoint with too large latitude should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointWithWrongPayloadFails() throws {
        try app
            .describe("Creating a user with wrong payload fails")
            .post(waypointsPath)
            .body(["wrong input": "Test Category"])
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}

// TODO: list only verified models
