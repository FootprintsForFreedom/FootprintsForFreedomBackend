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
    
    func testSuccessfulListVerifiedWaypointsWithPreferredLanguageReturnsVerifiedModelsForAllLanguagesButPrefersSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedWaypoint.load(on: app.db)
        // Create a second not verified model for the verified waypoint that should not be returned
        let _ = try await WaypointWaypointModel.createWith(title: "Not visible", description: "Not visible", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: verifiedWaypointRepository.requireID(), languageId: language.requireID(), userId: userId, verified: false, on: app.db)
        // Create a reposiotry that is only available in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, createdVerifiedWaypointInDifferentLanguage) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedWaypointInDifferentLanguage.load(on: app.db)
        // Create a reposiotry that is available in both languages
        let (verifiedWaypointRepositoryWithMultipleLanguages, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedWaypointInLanguage1 = try await WaypointWaypointModel.createWith(title: "Language 2", description: "Second description", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: verifiedWaypointRepositoryWithMultipleLanguages.requireID(), languageId: language.requireID(), userId: userId, verified: true, on: app.db)
        try await createdVerifiedWaypointInLanguage1.load(on: app.db)
        
        // Get verified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$waypoints) { $0.with(\.$language) }
            .all()
        
        let waypointCount = waypoints.count
        
        let verifiedWaypointCount = waypoints
            .filter { $0.waypoints.contains { $0.verified && $0.language.priority != nil } }
            .count
        
        try app
            .describe("List waypoints with perferred language should return ok and verified models for all languages. However, it should prefer the specified language")
            .get(waypointsPath.appending("?preferredLanguage=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Waypoint.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, verifiedWaypointCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, verifiedWaypointCount)
                XCTAssert(content.items.map { $0.id }.uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                let verifiedWaypoint = content.items.first { $0.id == verifiedWaypointRepository.id }!
                XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title.value)
                XCTAssertEqual(verifiedWaypoint.location, createdVerifiedWaypoint.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
                let verifiedWaypointInDifferentLanguage = content.items.first { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id }!
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.id, verifiedWaypointRepositoryInDifferentLanguage.id)
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.title, createdVerifiedWaypointInDifferentLanguage.title.value)
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.location, createdVerifiedWaypointInDifferentLanguage.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id })
                let verifiedWaypointWithMultipleLanguages = content.items.first { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id }!
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.id, verifiedWaypointRepositoryWithMultipleLanguages.id)
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.title, createdVerifiedWaypointInLanguage1.title.value)
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.location, createdVerifiedWaypointInLanguage1.location.value)
                
                XCTAssert(!content.items.contains { $0.id == unverifiedWaypointRepository.id })
            }
            .test()
    }
    
    func testSuccessfullListVerifiedWaypointsWithoutPreferredLanguageReturnsVerifiedModlesForAllLanguagesAccordingToTheirPriority() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedWaypoint.load(on: app.db)
        // Create a second not verified model for the verified waypoint that should not be returned
        let _ = try await WaypointWaypointModel.createWith(title: "Not visible", description: "Not visible", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: verifiedWaypointRepository.requireID(), languageId: language.requireID(), userId: userId, verified: false, on: app.db)
        // Create a reposiotry that is only available in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, createdVerifiedWaypointInDifferentLanguage) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedWaypointInDifferentLanguage.load(on: app.db)
        // Create a reposiotry that is available in both languages
        let (verifiedWaypointRepositoryWithMultipleLanguages, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedWaypointInLanguage1 = try await WaypointWaypointModel.createWith(title: "Language 2", description: "Second description", location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)), repositoryId: verifiedWaypointRepositoryWithMultipleLanguages.requireID(), languageId: language.requireID(), userId: userId, verified: true, on: app.db)
        try await createdVerifiedWaypointInLanguage1.load(on: app.db)
        
        // Get verified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$waypoints) { $0.with(\.$language) }
            .all()
        
        let waypointCount = waypoints.count
        
        let verifiedWaypointCount = waypoints
            .filter { $0.waypoints.contains { $0.verified && $0.language.priority != nil } }
            .count
        
        try app
            .describe("List waypoints should return ok")
            .get(waypointsPath.appending("?per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Waypoint.List>.self) { content in
                XCTAssertEqual(content.items.count, verifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                let verifiedWaypoint = content.items.first { $0.id == verifiedWaypointRepository.id }!
                XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title.value)
                XCTAssertEqual(verifiedWaypoint.location, createdVerifiedWaypoint.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
                let verifiedWaypointInDifferentLanguage = content.items.first { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id }!
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.id, verifiedWaypointRepositoryInDifferentLanguage.id)
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.title, createdVerifiedWaypointInDifferentLanguage.title.value)
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.location, createdVerifiedWaypointInDifferentLanguage.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id })
                let verifiedWaypointWithMultipleLanguages = content.items.first { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id }!
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.id, verifiedWaypointRepositoryWithMultipleLanguages.id)
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.title, createdVerifiedWaypointInLanguage1.title.value)
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.location, createdVerifiedWaypointInLanguage1.location.value)
                
                XCTAssert(!content.items.contains { $0.id == unverifiedWaypointRepository.id })
            }
            .test()
    }
    
    func testSuccessfullListVerifiedWaypointsDoesNotReturnModelsForDeactivatedLanguages() async throws {
        let language = try await createLanguage()
        let deactivatedLanguage = try await createLanguage()
        deactivatedLanguage.priority = nil
        try await deactivatedLanguage.update(on: app.db)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedWaypoint.load(on: app.db)
        
        // Create a waypoint for a deactivated language
        let (verifiedWaypointRepositoryForDeactivatedLanguage, _) = try await createNewWaypoint(verified: true, languageId: deactivatedLanguage.requireID(), userId: userId)
        
        // Get waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$waypoints) { $0.with(\.$language) }
            .all()
        
        let waypointCount = waypoints.count
        
        try app
            .describe("List waypoints should return ok")
            .get(waypointsPath.appending("?per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Waypoint.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                XCTAssertFalse(content.items.contains { $0.id == verifiedWaypointRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }
    
    // TODO: if unverified, require user to be creator or moderator
    // but there is no crator?!
    func testSuccessfullGetVerifiedWaypoint() async throws {
        let language = try await createLanguage()
        let (waypointRepository, waypoint) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.load(on: app.db)
        
        try app
            .describe("Get verified waypoint should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title.value)
                XCTAssertEqual(content.description, waypoint.description.value)
                XCTAssertEqual(content.location, waypoint.location.value)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNil(content.verified)
                XCTAssertNil(content.modelId)
            }
            .test()
    }
    
    func testSuccessfullGetUnverifiedWaypointAsModerator() async throws {
        let language = try await createLanguage()
        let (waypointRepository, waypoint) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.load(on: app.db)
        
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Get unverified waypoint as moderator should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title.value)
                XCTAssertEqual(content.description, waypoint.description.value)
                XCTAssertEqual(content.location, waypoint.location.value)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNotNil(content.verified)
                XCTAssertEqual(content.verified, waypoint.verified)
                XCTAssertNotNil(content.modelId)
                XCTAssertEqual(content.modelId, waypoint.id!)
            }
            .test()
    }
    
    func testGetWaypointForDeactivatedLanguageFails() async throws {
        let deactivatedLanguage = try await createLanguage()
        deactivatedLanguage.priority = nil
        try await deactivatedLanguage.update(on: app.db)
        
        let (waypointRepositoryForDeactivatedLanguage, waypointForDeactivatedLanguage) = try await createNewWaypoint(verified: true, languageId: deactivatedLanguage.requireID())
        try await waypointForDeactivatedLanguage.load(on: app.db)
        
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("Get waypoint for deactivated language should always fail; instead request the model directly")
            .get(waypointsPath.appending(waypointRepositoryForDeactivatedLanguage.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }
    
    func testGetUnverifiedWaypointAsUserFails() async throws {
        let (waypointRepository, _) = try await createNewWaypoint(verified: false)
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("Get unverified waypoint as moderator should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testGetUnverifiedWaypointWithoutTokenFails() async throws {
        let (waypointRepository, _) = try await createNewWaypoint(verified: false)
        
        try app
            .describe("Get unverified waypoint as moderator should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
}

