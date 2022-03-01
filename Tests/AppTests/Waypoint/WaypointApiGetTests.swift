//
//  WaypointApiGetTests.swift
//  
//
//  Created by niklhut on 19.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiGetTests: AppTestCase {
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
        waypointRepository.verified = verified
        waypointRepository.currentProperty.id = try waypointModel.requireID()
        waypointRepository.lastProperty.id = try waypointModel.requireID()
        try await waypointRepository.create(on: app.db)
        return waypointRepository
    }
    
    // TODO: dont list unverified waypoints
    func testSuccessfullListVerifiedWaypoints() async throws {
        let unverifiedWaypoint = try await createNewWaypoint()
        let verifiedWaypoint = try await createNewWaypoint(verified: true)
        
        // Get waypoint count
        let waypointCount = try await WaypointRepositoryModel
            .query(on: app.db)
            .filter(\.$verified, .equal, true)
            .count()
        
        try app
            .describe("List waypoints should return ok")
            .get(waypointsPath)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Waypoint.List>.self) { content in
                XCTAssertEqual(content.items.count, waypointCount)
                XCTAssert(content.items.contains { $0.id == verifiedWaypoint.id })
                XCTAssert(!content.items.contains { $0.id == unverifiedWaypoint.id })
            }
            .test()
    }
        
    // TODO: if unverified, require user to be creator or moderator
    // but there is no crator?!
    func testSuccessfullGetVerifiedWaypoint() async throws {
        let waypoint = try await createNewWaypoint(verified: true)
        try await waypoint.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        try app
            .describe("Get verified waypoint should return ok")
            .get(waypointsPath.appending(waypoint.requireID().uuidString))
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
    }
    
    func testSuccessfullGetUnverifiedWaypointAsModerator() async throws {
        let waypoint = try await createNewWaypoint(verified: false)
        try await waypoint.load(on: app.db)
        try await waypoint.current.load(on: app.db)
        
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("Get unverified waypoint as moderator should return ok")
            .get(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.id)
                XCTAssertEqual(content.title, waypoint.current.title.value)
                XCTAssertEqual(content.description, waypoint.current.description.value)
                XCTAssertEqual(content.location, waypoint.current.location.value)
                XCTAssertNotNil(content.verified)
                XCTAssertEqual(content.verified, waypoint.verified)
            }
            .test()
    }
    
    func testGetUnverifiedWaypointAsUserFails() async throws {
        let waypoint = try await createNewWaypoint(verified: false)
        let userToken = try await getTokenFromOtherUser(role: .user)
        
        try app
            .describe("Get unverified waypoint as moderator should return ok")
            .get(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testGetUnverifiedWaypointWithoutTokenFails() async throws {
        let waypoint = try await createNewWaypoint(verified: false)
        
        try app
            .describe("Get unverified waypoint as moderator should return ok")
            .get(waypointsPath.appending(waypoint.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
}

