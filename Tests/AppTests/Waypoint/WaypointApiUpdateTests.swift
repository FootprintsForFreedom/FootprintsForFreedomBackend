//
//  WaypointApiUpdateTests.swift
//  
//
//  Created by niklhut on 20.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Waypoint.Waypoint.Update: Content { }

final class WaypointApiUpdateTests: AppTestCaseWithToken {
    let waypointsPath = "api/waypoints/"

    private func createNewWaypoint(
        title: String = "New Waypoint Title",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> WaypointRepositoryModel {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let waypointModel = try await WaypointWaypointModel.createWith(title: title, description: description, location: location, userId: userId, on: app.db)
        let waypointRepository = WaypointRepositoryModel()
        waypointRepository.verified = false
        waypointRepository.currentProperty.id = try waypointModel.requireID()
        waypointRepository.lastProperty.id = try waypointModel.requireID()
        try await waypointRepository.create(on: app.db)
        return waypointRepository
    }
    
    private func getWaypointUpdateContent(
        title: String = "New Waypoint Title",
        updatedTitle: String = "Updated Title for Waypoint",
        description: String = "New Waypoint Description",
        updatedDescription: String = "Updated description for Waypoint",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        updatedLocation: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (model: WaypointRepositoryModel, updateContent: Waypoint.Waypoint.Update) {
        let waypoint = try await createNewWaypoint(title: title, description: description, location: location, verified: verified, userId: userId)
        let updateContent = Waypoint.Waypoint.Update(title: updatedTitle, description: updatedDescription, location: updatedLocation)
        return (waypoint, updateContent)
    }
    
    func testSucessfulUpdateWaypoint() async throws {
        let (waypoint, updateContent) = try await getWaypointUpdateContent()
        try await waypoint.currentProperty.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        try app
            .describe("Update waypoint should return ok and the old waypoint content since the new waypoint should be unverified")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.id)
                XCTAssertEqual(content.title, waypoint.current.title.value)
                XCTAssertEqual(content.description, waypoint.current.description.value)
                XCTAssertEqual(content.location, waypoint.current.location.value)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the waypoint models are linked correctly, and the values of the next model are correct
        try await waypoint.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        try await waypoint.current.nextProperty.load(on: app.db)
        let newWaypointModel = waypoint.current.next!
        try await newWaypointModel.load(on: app.db)
        XCTAssertEqual(newWaypointModel.title.value, updateContent.title)
        XCTAssertEqual(newWaypointModel.description.value, updateContent.description)
        XCTAssertEqual(newWaypointModel.location.value, updateContent.location)
        
        // Test the title, description and location inside are linked
        let previousTitle = newWaypointModel.title.previous!
        XCTAssertEqual(waypoint.current.title, previousTitle)
        let previousDescription = newWaypointModel.description.previous!
        XCTAssertEqual(waypoint.current.description, previousDescription)
        let previousLocation = newWaypointModel.location.previous!
        XCTAssertEqual(waypoint.current.location, previousLocation)
    }
    
    func testUpdateWaypointWithoutTokenFails() async throws {
        let (waypoint, updateContent) = try await getWaypointUpdateContent()
        
        try app
            .describe("Update waypoint should fail wihtout valid token")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateWaypointNeedsValidTitle() async throws {
        let (waypoint, updateContent) = try await getWaypointUpdateContent(updatedTitle: "")
        
        try app
            .describe("Update waypoint should fail with empty title")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidDescription() async throws {
        let (waypoint, updateContent) = try await getWaypointUpdateContent(updatedDescription: "")
        
        try app
            .describe("Update waypoint should fail with empty description")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsLocation() async throws {
        let waypoint = try await createNewWaypoint()
        struct Update: Content {
            let title: String
            let description: String
        }
        let updateContent = Update(title: "Updated Title", description: "This is updated")
        
        try app
            .describe("Update waypoint should fail without description")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidLatitude() async throws {
        let (waypoint, updateContent) = try await getWaypointUpdateContent(updatedLocation: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Update waypoint should fail with incorrect Latitude")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidLongitude() async throws {
        let (waypoint, updateContent) = try await getWaypointUpdateContent(updatedLocation: .init(latitude: 20, longitude: 181))
        
        try app
            .describe("Update waypoint should fail with incorrect longitude")
            .put(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
