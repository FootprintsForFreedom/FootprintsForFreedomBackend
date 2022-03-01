//
//  WaypointApiPatchTests.swift
//  
//
//  Created by niklhut on 27.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Waypoint.Waypoint.Patch: Content { }

final class WaypointApiPatchTests: AppTestCaseWithToken {
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
    
    private func getWaypointPatchContent(
        title: String = "New Waypoint Title",
        patchedTitle: String? = nil,
        description: String = "New Waypoint Description",
        patchedDescription: String? = nil,
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        patchedLocation: Waypoint.Location? = nil,
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (model: WaypointRepositoryModel, patchContent: Waypoint.Waypoint.Patch) {
        let waypoint = try await createNewWaypoint(title: title, description: description, location: location, verified: verified, userId: userId)
        let patchContent = Waypoint.Waypoint.Patch(title: patchedTitle, description: patchedDescription, location: patchedLocation)
        return (waypoint, patchContent)
    }
    
    func testEmptyPatchWaypointDoesNothing() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent()
        try await waypoint.currentProperty.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        // Get original waypoint count
        let waypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        
        try app
            .describe("Empty patch waypoint should return ok but change nothing")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
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
        
        // New waypoint count should be equal to original waypoint count
        let newWaypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
    }
    
    func testSuccessfulPatchWaypointTitle() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title")
        try await waypoint.currentProperty.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        try app
            .describe("Patch waypoint title should return ok and the old waypoint content since the new waypoint should be unverified")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
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
        XCTAssertEqual(newWaypointModel.title.value, patchContent.title)
        XCTAssertEqual(newWaypointModel.description.value, waypoint.current.description.value)
        XCTAssertEqual(newWaypointModel.location.value, waypoint.current.location.value)
        
        // Test the title inside is linked
        let previousTitle = newWaypointModel.title.previous!
        XCTAssertEqual(waypoint.current.title, previousTitle)
    }
    
    func testSuccessfulPatchWaypointDescription() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedDescription: "The patched description")
        try await waypoint.currentProperty.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        try app
            .describe("Patch waypoint description should return ok and the old waypoint content since the new waypoint should be unverified")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
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
        XCTAssertEqual(newWaypointModel.title.value, waypoint.current.title.value)
        XCTAssertEqual(newWaypointModel.description.value, patchContent.description)
        XCTAssertEqual(newWaypointModel.location.value, waypoint.current.location.value)
        
        // Test the description inside is linked
        let previousDescription = newWaypointModel.description.previous!
        XCTAssertEqual(waypoint.current.description, previousDescription)
    }
    
    func testSuccessfulPatchWaypointLocation() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)))
        try await waypoint.currentProperty.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        try app
            .describe("Patch waypoint title should return ok and the old waypoint content since the new waypoint should be unverified")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
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
        XCTAssertEqual(newWaypointModel.title.value, waypoint.current.title.value)
        XCTAssertEqual(newWaypointModel.description.value, waypoint.current.description.value)
        XCTAssertEqual(newWaypointModel.location.value, patchContent.location)
        
        // Test the location inside is linked
        let previousLocation = newWaypointModel.location.previous!
        XCTAssertEqual(waypoint.current.location, previousLocation)
    }
    
    func testPatchWaypointNeedsValidTitle() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedTitle: "")
        
        try app
            .describe("Patch waypoint should fail with empty title")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidDescription() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedDescription: "")
        
        try app
            .describe("Patch waypoint should fail with empty description")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
        
    func testPatchWaypointNeedsValidLatitude() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Patch waypoint should fail with incorrect Latitude")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidLongitude() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: 20, longitude: 181))
        
        try app
            .describe("Patch waypoint should fail with incorrect longitude")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointWithoutTokenFails() async throws {
        let (waypoint, patchContent) = try await getWaypointPatchContent()
        
        try app
            .describe("Patch waypoint should fail wihtout valid token")
            .patch(waypointsPath.appending(waypoint.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
}
