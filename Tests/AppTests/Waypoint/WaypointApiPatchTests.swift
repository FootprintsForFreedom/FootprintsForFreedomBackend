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
    
    private func createNewWaypoint(
        title: String = "New Waypoint Title",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: WaypointRepositoryModel, model: WaypointWaypointModel) {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        let waypointRepository = WaypointRepositoryModel()
        try await waypointRepository.create(on: app.db)
        
        let languageId: UUID = try await {
            if let languageId = languageId {
                return languageId
            } else {
                return try await createLanguage().requireID()
            }
        }()
        
        let waypointModel = try await WaypointWaypointModel.createWith(
            title: title,
            description: description,
            location: location,
            repositoryId: waypointRepository.requireID(),
            languageId: languageId,
            userId: userId,
            verified: verified,
            on: app.db
        )
        return (waypointRepository, waypointModel)
    }
    
    private func getWaypointPatchContent(
        title: String = "New Waypoint Title",
        patchedTitle: String? = nil,
        description: String = "New Waypoint Description",
        patchedDescription: String? = nil,
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        patchedLocation: Waypoint.Location? = nil,
        languageId: UUID? = nil,
        patchLangugageCode: String = "en",
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (waypointRepository: WaypointRepositoryModel, createdModel: WaypointWaypointModel, patchContent: Waypoint.Waypoint.Patch) {
        let (waypointRepository, createdModel) = try await createNewWaypoint(title: title, description: description, location: location, verified: verified, languageId: languageId, userId: userId)
        let updateContent = Waypoint.Waypoint.Patch(title: patchedTitle, description: patchedDescription, location: patchedLocation, languageCode: patchLangugageCode)
        return (waypointRepository, createdModel, updateContent)
    }
    
    func testSuccessfulPatchWaypointTitle() async throws {
        let (waypointRepository, createdModel, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title")
        createdModel.verified = true
        try await createdModel.update(on: app.db)
        try await createdModel.load(on: app.db)
        
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
                XCTAssertEqual(content.description, createdModel.description.value)
                XCTAssertEqual(content.location, createdModel.location.value)
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
        let (waypointRepository, createdModel, patchContent) = try await getWaypointPatchContent(patchedDescription: "The patched description")
        createdModel.verified = true
        try await createdModel.update(on: app.db)
        try await createdModel.load(on: app.db)
        
        try app
            .describe("Patch waypoint description should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, createdModel.title.value)
                XCTAssertEqual(content.description, patchContent.description)
                XCTAssertEqual(content.location, createdModel.location.value)
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
        let (waypointRepository, createdModel, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)))
        createdModel.verified = true
        try await createdModel.update(on: app.db)
        try await createdModel.load(on: app.db)
        
        try app
            .describe("Patch waypoint location should return ok")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, createdModel.title.value)
                XCTAssertEqual(content.description, createdModel.description.value)
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
        let (waypointRepository, createdModel, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title", patchedDescription: "The patched description", patchedLocation: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)))
        try await createdModel.load(on: app.db)
        
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
        let (waypointRepository, createdModel, patchContent) = try await getWaypointPatchContent(patchedTitle: "The patched title", patchedDescription: "The patched description")
        try await createdModel.load(on: app.db)
        
        try app
            .describe("Patch waypoint without verified model in the specified language should fail")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testEmptyPatchWaypointFails() async throws {
        let (waypointRepository, _, patchContent) = try await getWaypointPatchContent()
        
        try app
            .describe("Empty patch waypoint should fail since a property should change to patch")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidTitle() async throws {
        let (waypointRepository, _, patchContent) = try await getWaypointPatchContent(patchedTitle: "")
        
        try app
            .describe("Patch waypoint should fail with empty title")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidDescription() async throws {
        let (waypointRepository, _, patchContent) = try await getWaypointPatchContent(patchedDescription: "")
        
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
        let (waypointRepository1, _, updateContent1) = try await getWaypointPatchContent(languageId: language.requireID(), patchLangugageCode: "")
        let (waypointRepository2, _, updateContent2) = try await getWaypointPatchContent(languageId: language.requireID(), patchLangugageCode: "hi")
        
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
        let (waypointRepository, _, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Patch waypoint should fail with incorrect Latitude")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointNeedsValidLongitude() async throws {
        let (waypointRepository, _, patchContent) = try await getWaypointPatchContent(patchedLocation: .init(latitude: 20, longitude: 181))
        
        try app
            .describe("Patch waypoint should fail with incorrect longitude")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchWaypointWithoutTokenFails() async throws {
        let (waypointRepository, _, patchContent) = try await getWaypointPatchContent()
        
        try app
            .describe("Patch waypoint should fail wihtout valid token")
            .patch(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
}
