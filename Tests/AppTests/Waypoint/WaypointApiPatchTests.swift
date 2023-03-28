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

extension Waypoint.Detail.Patch: Content { }

final class WaypointApiPatchTests: AppTestCase, WaypointTest {
    private func getWaypointPatchContent(
        title: String = "New Waypoint Title \(UUID())",
        patchedTitle: String? = nil,
        detailText: String = "New Waypoint detail text",
        patchedDetailText: String? = nil,
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        patchedLocation: Waypoint.Location? = nil,
        languageId: UUID? = nil,
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (waypointRepository: WaypointRepositoryModel, createdModel: WaypointDetailModel, createdLocation: WaypointLocationModel, patchContent: Waypoint.Detail.Patch) {
        let (waypointRepository, createdModel, createdLocation) = try await createNewWaypoint(
            title: title,
            detailText: detailText,
            verified: verified,
            languageId: languageId,
            userId: userId
        )
        try await createdModel.$language.load(on: app.db)
        let patchContent = try Waypoint.Detail.Patch(
            title: patchedTitle,
            detailText: patchedDetailText,
            location: patchedLocation,
            idForWaypointDetailToPatch: createdModel.requireID()
        )
        return (waypointRepository, createdModel, createdLocation, patchContent)
    }
    
    func testSuccessfulPatchWaypointTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, createdLocation, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title \(UUID())", verified: true)
        try await createdModel.$language.load(on: app.db)
        
        try app
            .describe("Patch waypoint title should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.detailText, createdModel.detailText)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, createdModel.language.languageCode)
            }
            .test()
        
        // Test the new waypoint model was created correctly
        let newWaypointModel = try await waypointRepository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newWaypointModel.id)
        XCTAssertNil(newWaypointModel.verifiedAt)
    }
    
    func testSuccessfulPatchWaypointTitleWithDuplicateTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let title = "My new title \(UUID())"
        let (waypointRepository, createdModel, createdLocation, patchContent) = try await getWaypointPatchContent(title: title, patchedTitle: title, verified: true)
        try await createdModel.$language.load(on: app.db)
        
        try app
            .describe("Patch waypoint title should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.detailText, createdModel.detailText)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, createdModel.language.languageCode)
            }
            .test()
    }

    
    func testSuccessfulPatchWaypointDetailText() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, createdLocation, patchContent) = try await getWaypointPatchContent(patchedDetailText: "The patched detailText", verified: true)
        try await createdModel.$language.load(on: app.db)
        
        try app
            .describe("Patch waypoint detailText should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, createdModel.title)
                XCTAssertNotEqual(content.slug, createdModel.title.slugify())
                XCTAssertContains(content.slug, createdModel.title.slugify())
                XCTAssertEqual(content.detailText, patchContent.detailText)
                XCTAssertEqual(content.location, createdLocation.location)
                XCTAssertEqual(content.languageCode, createdModel.language.languageCode)
            }
            .test()
        
        // Test the new waypoint model was created correctly
        let newWaypointModel = try await waypointRepository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newWaypointModel.id)
        XCTAssertNil(newWaypointModel.verifiedAt)
    }
    
    func testSuccessfulPatchWaypointLocation() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, _, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), verified: true)
        try await createdModel.$language.load(on: app.db)
        
        try app
            .describe("Patch waypoint location should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, createdModel.title)
                XCTAssertEqual(content.slug, createdModel.slug)
                XCTAssertEqual(content.detailText, createdModel.detailText)
                XCTAssertEqual(content.location, patchContent.location)
                XCTAssertEqual(content.languageCode, createdModel.language.languageCode)
            }
            .test()
        
        // Test the new waypoint model was created correctly
        let newLocationModel = try await waypointRepository.$locations
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newLocationModel.id)
        XCTAssertNil(newLocationModel.verifiedAt)
    }
    
    func testSuccessfulPatchWithoutVerifiedModelInSpecifiedLanguageWhenAllParametersAreSet() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, createdModel, _, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title \(UUID())", patchedDetailText: "The patched detailText", patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)))
        try await createdModel.$language.load(on: app.db)
        
        try app
            .describe("Patch waypoint without verified model in the specified language should fail")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertNotEqual(content.slug, patchContent.title!.slugify())
                XCTAssertContains(content.slug, patchContent.title!.slugify())
                XCTAssertEqual(content.detailText, patchContent.detailText)
                XCTAssertEqual(content.location, patchContent.location)
                XCTAssertEqual(content.languageCode, createdModel.language.languageCode)
            }
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
    
    func testPatchWaypointNeedsValidDetailText() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedDetailText: "")
        
        try app
            .describe("Patch waypoint should fail with empty detailText")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValididForWaypointDetailToPatch() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (waypointRepository, _, _, _) = try await getWaypointPatchContent(verified: true)
        let patchContent = Media.Detail.Patch(title: nil, detailText: nil, source: nil, idForMediaDetailToPatch: UUID())
        
        try app
            .describe("Patch waypoint with should need valid id for waypoint to patch or fail")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
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
        let (waypointRepository, _, _, patchContent) = try await getWaypointPatchContent(patchedDetailText: "new detailText")
        
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
