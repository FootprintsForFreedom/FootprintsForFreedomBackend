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

final class WaypointApiUpdateTests: AppTestCase, WaypointTest {
    let waypointsPath = "api/waypoints/"
    
    private func getWaypointUpdateContent(
        title: String = "New Waypoint Title",
        updatedTitle: String = "Updated Title for Waypoint",
        description: String = "New Waypoint Description",
        updatedDescription: String = "Updated description for Waypoint",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        updatedLocation: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        languageId: UUID? = nil,
        updateLangugageCode: String = "de",
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (repository: WaypointRepositoryModel, createdLocation: WaypointLocationModel, updateContent: Waypoint.Waypoint.Update) {
        let (waypointRepository, _, createdLocation) = try await createNewWaypoint(
            title: title,
            description: description,
            location: location,
            verified: verified,
            languageId: languageId,
            userId: userId
        )
        let updateContent = Waypoint.Waypoint.Update(
            title: updatedTitle,
            description: updatedDescription,
            languageCode: updateLangugageCode
        )
        return (waypointRepository, createdLocation, updateContent)
    }
    
    func testSucessfulUpdateWaypoint() async throws {
        let token = try await getToken(for: .user)
        let (waypointRepository, createdLocation, updateContent) = try await getWaypointUpdateContent()
        
        let locationCount = try await WaypointLocationModel
            .query(on: app.db)
            .count()
        
        try app
            .describe("Update waypoint should return ok and the new waypoint content")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.description, updateContent.description)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the new waypoint model was created correctly
        let newWaypointModel = try await waypointRepository.$waypoints
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newWaypointModel.id)
        XCTAssertFalse(newWaypointModel.verified)
        
        // test it does not update the location
        let newLocationCount = try await WaypointLocationModel
            .query(on: app.db)
            .count()
        XCTAssertEqual(locationCount, newLocationCount)
    }
    
    func testSuccessfulUpdateWithNewLanguage() async throws {
        let token = try await getToken(for: .user)
        let (waypointRepository, _, createdLocation) = try await createNewWaypoint()
        let secondLanguage = try await createLanguage(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false)
        
        let updateContent = Waypoint.Waypoint.Update(
            title: "Language 2",
            description: "Description for additional language",
            languageCode: secondLanguage.languageCode
        )
        
        try app
            .describe("Update waypoint with new language should return ok and the new waypoint content")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.description, updateContent.description)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the new waypoint model was created correctly
        let newWaypointModel = try await waypointRepository.$waypoints
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newWaypointModel.id)
        XCTAssertFalse(newWaypointModel.verified)
    }
    
    func testUpdateWaypointWithoutTokenFails() async throws {
        let (waypointRepository, _, updateContent) = try await getWaypointUpdateContent()
        
        try app
            .describe("Update waypoint should fail wihtout valid token")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateWaypointNeedsValidTitle() async throws {
        let token = try await getToken(for: .user)
        let (waypointRepository, _, updateContent) = try await getWaypointUpdateContent(updatedTitle: "")
        
        try app
            .describe("Update waypoint should fail with empty title")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidDescription() async throws {
        let token = try await getToken(for: .user)
        let (waypointRepository, _, updateContent) = try await getWaypointUpdateContent(updatedDescription: "")
        
        try app
            .describe("Update waypoint should fail with empty description")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidLanguageCode() async throws {
        let language = try await createLanguage()
        let token = try await getToken(for: .user)
        let (waypointRepository1, _, updateContent1) = try await getWaypointUpdateContent(languageId: language.requireID(), updateLangugageCode: "")
        let (waypointRepository2, _, updateContent2) = try await getWaypointUpdateContent(languageId: language.requireID(), updateLangugageCode: "hi")
        
        try app
            .describe("Update waypoint with empty language code should fail")
            .put(waypointsPath.appending(waypointRepository1.requireID().uuidString))
            .body(updateContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Update waypoint with non-existent language code should fail")
            .put(waypointsPath.appending(waypointRepository2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
