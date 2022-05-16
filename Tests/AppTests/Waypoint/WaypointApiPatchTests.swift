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

final class WaypointApiPatchTests: AppTestCase, WaypointTest {
    let waypointsPath = "api/waypoints/"
    
    private func getWaypointPatchContent(
        title: String = "New Waypoint Title",
        patchedTitle: String? = nil,
        description: String = "New Waypoint Description",
        patchedDescription: String? = nil,
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        patchedLocation: Waypoint.Location? = nil,
        languageId: UUID? = nil,
        patchLangugageCode: String? = nil,
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (waypointRepository: WaypointRepositoryModel, createdModel: WaypointWaypointModel, createdLocation: WaypointLocationModel, patchContent: Waypoint.Waypoint.Patch) {
        let (waypointRepository, createdModel, createdLocation) = try await createNewWaypoint(
            title: title,
            description: description,
            verified: verified,
            languageId: languageId,
            userId: userId
        )
        try await createdModel.$language.load(on: app.db)
        let patchContent = Waypoint.Waypoint.Patch(title: patchedTitle, description: patchedDescription, location: patchedLocation, languageCode: patchLangugageCode ?? createdModel.language.languageCode)
        return (waypointRepository, createdModel, createdLocation, patchContent)
    }
    
    func testSuccessfulPatchWaypointTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, createdLocation, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title", verified: true)
        
        try app
            .describe("Patch waypoint title should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertEqual(content.description, createdModel.description)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, patchContent.languageCode)
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
    
    func testSuccessfulPatchWaypointDescription() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, createdLocation, patchContent) = try await getWaypointPatchContent(patchedDescription: "The patched description", verified: true)
        
        try app
            .describe("Patch waypoint description should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, createdModel.title)
                XCTAssertEqual(content.description, patchContent.description)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, patchContent.languageCode)
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
    
    func testSuccessfulPatchWaypointLocation() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, _, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), verified: true)
        
        try app
            .describe("Patch waypoint location should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, createdModel.title)
                XCTAssertEqual(content.description, createdModel.description)
                XCTAssertEqual(content.location, patchContent.location)
                XCTAssertEqual(content.languageCode, patchContent.languageCode)
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
    
    func testSuccessfulPatchWithoutVerifiedModelInSpecifiedLanguageWhenAllParametersAreSet() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title", patchedDescription: "The patched description", patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)))
        
        try app
            .describe("Patch waypoint without verified model in the specified language should fail")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertEqual(content.description, patchContent.description)
                XCTAssertEqual(content.location, patchContent.location)
                XCTAssertEqual(content.languageCode, patchContent.languageCode)
                XCTAssertNil(content.verified)
            }
            .test()
    }
    
    func testPatchWithoutVerifiedModelInSpecifiedLanguageFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title")
        
        try app
            .describe("Patch waypoint without verified model in the specified language should fail")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testEmptyPatchWaypointFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent()
        
        try app
            .describe("Empty patch waypoint should fail since a property should change to patch")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedTitle: "")
        
        try app
            .describe("Patch waypoint should fail with empty title")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidDescription() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedDescription: "")
        
        try app
            .describe("Patch waypoint should fail with empty description")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidLanguageCode() async throws {
        let language = try await createLanguage()
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository1, _, _, updateContent1) = try await getWaypointPatchContent(languageId: language.requireID(), patchLangugageCode: "")
        let (waypointRepository2, _, _, updateContent2) = try await getWaypointPatchContent(languageId: language.requireID(), patchLangugageCode: "hi")
        
        try app
            .describe("Patch waypoint with empty language code should fail")
            .patch(waypointsPath.appending(waypointRepository1.requireID().uuidString))
            .body(updateContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Patch waypoint with non-existent language code should fail")
            .patch(waypointsPath.appending(waypointRepository2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidLatitude() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Patch waypoint should fail with incorrect Latitude")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidLongitude() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: 20, longitude: 181))
        
        try app
            .describe("Patch waypoint should fail with incorrect longitude")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedDescription: "new description")
        
        try app
            .describe("Patch waypoint as unverified user should fail")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchWaypointWithoutTokenFails() async throws {
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent()
        
        try app
            .describe("Patch waypoint should fail wihtout valid token")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
}
