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
    
    private func getWaypointUpdateContent(
        title: String = "New Waypoint Title",
        updatedTitle: String = "Updated Title for Waypoint",
        description: String = "New Waypoint Description",
        updatedDescription: String = "Updated description for Waypoint",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        updatedLocation: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        languageId: UUID? = nil,
        updateLangugageCode: String = "en",
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> (repository: WaypointRepositoryModel, updateContent: Waypoint.Waypoint.Update) {
        let (waypointRepository, _) = try await createNewWaypoint(title: title, description: description, location: location, verified: verified, languageId: languageId, userId: userId)
        let updateContent = Waypoint.Waypoint.Update(title: updatedTitle, description: updatedDescription, location: updatedLocation, languageCode: updateLangugageCode)
        return (waypointRepository, updateContent)
    }
    
    func testSucessfulUpdateWaypoint() async throws {
        let (waypointRepository, updateContent) = try await getWaypointUpdateContent()
        
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
                XCTAssertEqual(content.location, updateContent.location)
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
    
    func testSuccessfulUpdateWithNewLanguage() async throws {
        let (waypointRepository, _) = try await createNewWaypoint()
        let secondLanguage = try await createLanguage(languageCode: "ab", name: "Language", isRTL: false)
        
        let updateContent = Waypoint.Waypoint.Update(
            title: "Language 2",
            description: "Description for additional language",
            location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
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
                XCTAssertEqual(content.location, updateContent.location)
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
        let (waypointRepository, updateContent) = try await getWaypointUpdateContent()
        
        try app
            .describe("Update waypoint should fail wihtout valid token")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateWaypointNeedsValidTitle() async throws {
        let (waypointRepository, updateContent) = try await getWaypointUpdateContent(updatedTitle: "")
        
        try app
            .describe("Update waypoint should fail with empty title")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidDescription() async throws {
        let (waypointRepository, updateContent) = try await getWaypointUpdateContent(updatedDescription: "")
        
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
        let (waypointRepository1, updateContent1) = try await getWaypointUpdateContent(languageId: language.requireID(), updateLangugageCode: "")
        let (waypointRepository2, updateContent2) = try await getWaypointUpdateContent(languageId: language.requireID(), updateLangugageCode: "hi")
        
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
    
    func testUpdateWaypointNeedsLocation() async throws {
        let (waypointRepository, _) = try await createNewWaypoint()
        struct Update: Content {
            let title: String
            let description: String
            let languageCode: String
        }
        // the language with this code is stil created when getting the new waypoint repository
        let updateContent = Update(title: "Updated Title", description: "This is updated", languageCode: "en")
        
        try app
            .describe("Update waypoint should fail without description")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidLatitude() async throws {
        let (waypointRepository, updateContent) = try await getWaypointUpdateContent(updatedLocation: .init(latitude: 91, longitude: 20))
        
        try app
            .describe("Update waypoint should fail with incorrect Latitude")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateWaypointNeedsValidLongitude() async throws {
        let (waypointRepository, updateContent) = try await getWaypointUpdateContent(updatedLocation: .init(latitude: 20, longitude: 181))
        
        try app
            .describe("Update waypoint should fail with incorrect longitude")
            .put(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
