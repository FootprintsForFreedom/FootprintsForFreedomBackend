//
//  WaypointApiListUnverifiedTests.swift
//  
//
//  Created by niklhut on 14.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiListUnverifiedTests: AppTestCase {
    let waypointsPath = "api/waypoints/"
    
    private func createLanguage(
        languageCode: String = UUID().uuidString,
        name: String = UUID().uuidString,
        isRTL: Bool = false
    ) async throws -> LanguageModel {
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
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
    
    func testSuccessfulListRepositoriesWithUnverifiedModels() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, createdUnverifiedWaypoint) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedWaypoint.load(on: app.db)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedWaypoint.load(on: app.db)
        // Create a second not verified model for the verified waypoint
        let _ = try await WaypointWaypointModel.createWith(title: "Not visible", description: "Not visible", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: verifiedWaypointRepository.requireID(), languageId: language.requireID(), userId: userId, verified: false, on: app.db)
        // Create a waypoint in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        
        // Get unverified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$waypoints) { $0.with(\.$language) }
            .all()
        
        let waypointCount = waypoints.count
        
        let verifiedWaypointCount = waypoints
            .filter { $0.waypoints.contains { !$0.verified && $0.language.priority != nil } }
            .count
        
        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(waypointsPath.appending("unverified/?preferredLanguage=\(language.languageCode)&per=\(waypointCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Waypoint.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, verifiedWaypointCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, verifiedWaypointCount)
                XCTAssert(content.items.map { $0.id }.uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == unverifiedWaypointRepository.id })
                let unverifiedWaypoint = content.items.first { $0.id == unverifiedWaypointRepository.id }!
                XCTAssertEqual(unverifiedWaypoint.id, unverifiedWaypointRepository.id)
                XCTAssertEqual(unverifiedWaypoint.title, createdUnverifiedWaypoint.title.value)
                XCTAssertEqual(unverifiedWaypoint.location, createdUnverifiedWaypoint.location.value)
                
                // contains the verified waypoint repository because it has a second unverified waypoint model
                // here it should also return the verified model in the list for preview to see which waypoint was edited
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                let verifiedWaypoint = content.items.first { $0.id == verifiedWaypointRepository.id }!
                XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title.value)
                XCTAssertEqual(verifiedWaypoint.location, createdVerifiedWaypoint.location.value)
                
                XCTAssertFalse(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
            }
            .test()
    }
    
    func testListRepositoriesWithUnverifedModelsAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(waypointsPath.appending("unverified"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListRepositoriesWithUnverifedModelsWithoutTokenFails() async throws {
        try app
            .describe("List repositories with unverified models without token should return fail")
            .get(waypointsPath.appending("unverified"))
            .expect(.unauthorized)
            .test()
    }
    
    func testSuccessfulListUnverifiedModelsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (waypointRepository, createdUnverifiedWaypoint) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedWaypoint.load(on: app.db)
        // Create a verified waypoint for the same repository
        let verifiedWaypoint = try await WaypointWaypointModel.createWith(title: "Verified Waypoint", description: "This is text", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: waypointRepository.requireID(), languageId: language.requireID(), userId: userId, verified: true, on: app.db)
        // Create a second not verified waypoint for the same repository
        let secondCreatedUnverifiedWaypoint = try await WaypointWaypointModel.createWith(title: "Not visible", description: "Not visible", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: waypointRepository.requireID(), languageId: language.requireID(), userId: userId, verified: false, on: app.db)
        try await secondCreatedUnverifiedWaypoint.load(on: app.db)
        // Create a second not verified waypoint for the same repository in another language
        let createdUnverifiedWaypointInDifferentLanguage = try await WaypointWaypointModel.createWith(title: "Different Language", description: "Not visible, other language", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: waypointRepository.requireID(), languageId: language2.requireID(), userId: userId, verified: false, on: app.db)
        try await createdUnverifiedWaypointInDifferentLanguage.load(on: app.db)
        // Create a not verified waypoint for another repository
        let (_, unverifiedWaypointForDifferentRepository) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        
        // Get unverified and verified waypoint count
        let waypointCount = try await WaypointWaypointModel
            .query(on: app.db)
            .count()
        
        let unverifiedWaypointForRepositoryCount = try await WaypointWaypointModel
            .query(on: app.db)
            .filter(\.$verified == false)
            .filter(\.$repository.$id == waypointRepository.requireID())
            .count()
        
        try app
            .describe("List unverified should return ok and unverified models for all languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/unverified/?per=\(waypointCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Waypoint.ListUnverified>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedWaypointForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.modelId }.uniqued().count, unverifiedWaypointForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.modelId }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedWaypointForRepositoryCount)
                
                XCTAssert(content.items.contains { $0.modelId == createdUnverifiedWaypoint.id })
                let unverifiedWaypoint = content.items.first { $0.modelId == createdUnverifiedWaypoint.id }!
                XCTAssertEqual(unverifiedWaypoint.modelId, createdUnverifiedWaypoint.id)
                XCTAssertEqual(unverifiedWaypoint.title, createdUnverifiedWaypoint.title.value)
                XCTAssertEqual(unverifiedWaypoint.description, createdUnverifiedWaypoint.description.value)
                XCTAssertEqual(unverifiedWaypoint.languageCode, createdUnverifiedWaypoint.language.languageCode)
                
                XCTAssertFalse(content.items.contains { $0.modelId == verifiedWaypoint.id })
                
                XCTAssert(content.items.contains { $0.modelId == secondCreatedUnverifiedWaypoint.id })
                let secondUnverifiedWaypoint = content.items.first { $0.modelId == secondCreatedUnverifiedWaypoint.id }!
                XCTAssertEqual(secondUnverifiedWaypoint.modelId, secondCreatedUnverifiedWaypoint.id)
                XCTAssertEqual(secondUnverifiedWaypoint.title, secondCreatedUnverifiedWaypoint.title.value)
                XCTAssertEqual(secondUnverifiedWaypoint.description, secondCreatedUnverifiedWaypoint.description.value)
                XCTAssertEqual(secondUnverifiedWaypoint.languageCode, secondCreatedUnverifiedWaypoint.language.languageCode)
                
                XCTAssert(content.items.contains { $0.modelId == createdUnverifiedWaypointInDifferentLanguage.id })
                let unverifiedWaypointInDifferentLanguage = content.items.first { $0.modelId == createdUnverifiedWaypointInDifferentLanguage.id }!
                XCTAssertEqual(unverifiedWaypointInDifferentLanguage.modelId, createdUnverifiedWaypointInDifferentLanguage.id)
                XCTAssertEqual(unverifiedWaypointInDifferentLanguage.title, createdUnverifiedWaypointInDifferentLanguage.title.value)
                XCTAssertEqual(unverifiedWaypointInDifferentLanguage.description, createdUnverifiedWaypointInDifferentLanguage.description.value)
                XCTAssertEqual(unverifiedWaypointInDifferentLanguage.languageCode, createdUnverifiedWaypointInDifferentLanguage.language.languageCode)
                
                XCTAssertFalse(content.items.contains { $0.modelId == unverifiedWaypointForDifferentRepository.id })
            }
            .test()
    }
    
    func testListUnverifiedModelsForRepositoryAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        // Create an unverified waypoint
        let (waypointRepository, _) = try await createNewWaypoint()
        
        try app
            .describe("List unverified should return ok and unverified models for all languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/unverified/"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedModelsForRepositoryWithoutTokenFails() async throws {
        // Create an unverified waypoint
        let (waypointRepository, _) = try await createNewWaypoint()
        
        try app
            .describe("List unverified should return ok and unverified models for all languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/unverified/"))
            .expect(.unauthorized)
            .test()
    }
}
