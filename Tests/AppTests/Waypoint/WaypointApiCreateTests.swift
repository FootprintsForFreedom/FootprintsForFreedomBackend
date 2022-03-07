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
    
    private func createLanguage(
        languageCode: String = "en",
        name: String = "English",
        isRTL: Bool = false
    ) async throws -> LanguageModel {
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        let language = LanguageModel(languageCode: languageCode, name: name, isRTL: isRTL, priority: highestPriority + 1)
        try await language.create(on: app.db)
        return language
    }
    
    private func getWaypointCreateContent(
        title: String = "New Waypoint Title \(UUID())",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        languageCode: String? = nil
    ) async throws -> Waypoint.Waypoint.Create {
        var languageCode: String! = languageCode
        if languageCode == nil {
            languageCode = try await createLanguage().languageCode
        }
        return .init(title: title, description: description, location: location, languageCode: languageCode)
    }
    
    func testSuccessfulCreateWaypoint() async throws {
        let newWaypoint = try await getWaypointCreateContent()
        
        // Get original waypoint count
        let waypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        var newRepositoryId: UUID!
        
        try app
            .describe("Create waypoint should return ok")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.created)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertNotNil(content.id)
                newRepositoryId = content.id
                XCTAssertEqual(content.title, newWaypoint.title)
                XCTAssertEqual(content.description, newWaypoint.description)
                XCTAssertEqual(content.location, newWaypoint.location)
                XCTAssertEqual(content.languageCode, newWaypoint.languageCode)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // New waypoint count should be one more than original waypoint count
        let newWaypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount + 1)
        
        // check the new model is unverified
        let waypoint = try await WaypointRepositoryModel
            .find(newRepositoryId, on: app.db)!
            .$waypoints
            .query(on: app.db)
            .sort(\.$createdAt, .descending)
            .first()!
        XCTAssertFalse(waypoint.verified)
    }
    
    func testSuccessfulCreateWaypointAsModerator() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let newWaypoint = try await getWaypointCreateContent()
        
        // Get original waypoint count
        let waypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        var newRepositoryId: UUID!
        
        try app
            .describe("Create waypoint should return ok")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(moderatorToken)
            .expect(.created)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertNotNil(content.id)
                newRepositoryId = content.id
                XCTAssertEqual(content.title, newWaypoint.title)
                XCTAssertEqual(content.description, newWaypoint.description)
                XCTAssertEqual(content.location, newWaypoint.location)
                XCTAssertEqual(content.languageCode, newWaypoint.languageCode)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // New waypoint count should be one more than original waypoint count
        let newWaypointCount = try await WaypointWaypointModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount + 1)
        
        // check the new model is unverified
        let waypoint = try await WaypointRepositoryModel
            .find(newRepositoryId, on: app.db)!
            .$waypoints
            .query(on: app.db)
            .sort(\.$createdAt, .descending)
            .first()!
        XCTAssertFalse(waypoint.verified)
    }
    
    func testCreateWaypointWithoutTokenFails() async throws {
        let newWaypoint = try await getWaypointCreateContent()
        
        try app
            .describe("Create waypoint without token should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateWaypointNeedsValidTitle() async throws {
        let newWaypoint = try await getWaypointCreateContent(title: "")
        
        try app
            .describe("Create waypoint with empty title should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsValidDescription() async throws {
        let newWaypoint = try await getWaypointCreateContent(description: "")
        
        try app
            .describe("Create waypoint with empty description should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsValidLanguageCode() async throws {
        let newWaypoint1 = try await getWaypointCreateContent(languageCode: "")
        let newWaypoint2 = try await getWaypointCreateContent(languageCode: "hi")
        
        try app
            .describe("Create waypoint with empty language code should fail")
            .post(waypointsPath)
            .body(newWaypoint1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Create waypoint with non-existent language code should fail")
            .post(waypointsPath)
            .body(newWaypoint2)
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
        let newWaypoint = try await getWaypointCreateContent(location: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Create waypoint with too large latitude should fail")
            .post(waypointsPath)
            .body(newWaypoint)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateWaypointNeedsValidLongitude() async throws {
        let newWaypoint = try await getWaypointCreateContent(location: .init(latitude: 20, longitude: 181))
        
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
