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

final class WaypointApiGetTests: AppTestCase, WaypointTest {
    let waypointsPath = "api/waypoints/"
    
    func testSuccessfulListVerifiedWaypointsWithPreferredLanguageReturnsVerifiedModelsForAllLanguagesButPrefersSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint, _) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedWaypoint.$language.load(on: app.db)
        // Create a second not verified model for the verified waypoint that should not be returned
        let _ = try await WaypointWaypointModel.createWith(
            title: "Not visible",
            description: "Not visible",
            repositoryId: verifiedWaypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: false,
            on: app.db
        )
        // Create a reposiotry that is only available in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, createdVerifiedWaypointInDifferentLanguage, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedWaypointInDifferentLanguage.$language.load(on: app.db)
        // Create a reposiotry that is available in both languages
        let (verifiedWaypointRepositoryWithMultipleLanguages, _, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedWaypointInLanguage1 = try await WaypointWaypointModel.createWith(
            title: "Language 2",
            description: "Second description",
            repositoryId: verifiedWaypointRepositoryWithMultipleLanguages.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: true,
            on: app.db
        )
        try await createdVerifiedWaypointInLanguage1.$language.load(on: app.db)
        
        // Get verified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$waypoints) { $0.with(\.$language) }
            .with(\.$locations)
            .all()
        
        let waypointCount = waypoints.count
        
        let verifiedWaypointCount = waypoints
            .filter { $0.waypoints.contains { $0.verified && $0.language.priority != nil } && $0.locations.contains { $0.verified } }
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
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                let verifiedWaypoint = content.items.first { $0.id == verifiedWaypointRepository.id }!
                XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title)
//                XCTAssertEqual(verifiedWaypoint.location, createdVerifiedWaypoint.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
                let verifiedWaypointInDifferentLanguage = content.items.first { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id }!
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.id, verifiedWaypointRepositoryInDifferentLanguage.id)
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.title, createdVerifiedWaypointInDifferentLanguage.title)
//                XCTAssertEqual(verifiedWaypointInDifferentLanguage.location, createdVerifiedWaypointInDifferentLanguage.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id })
                let verifiedWaypointWithMultipleLanguages = content.items.first { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id }!
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.id, verifiedWaypointRepositoryWithMultipleLanguages.id)
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.title, createdVerifiedWaypointInLanguage1.title)
//                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.location, createdVerifiedWaypointInLanguage1.location.value)
                
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
        let (unverifiedWaypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint, _) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified waypoint that should not be returned
        let _ = try await WaypointWaypointModel.createWith(
            title: "Not visible",
            description: "Not visible",
            repositoryId: verifiedWaypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: false,
            on: app.db
        )
        // Create a reposiotry that is only available in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, createdVerifiedWaypointInDifferentLanguage, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedWaypointInDifferentLanguage.$language.load(on: app.db)
        // Create a reposiotry that is available in both languages
        let (verifiedWaypointRepositoryWithMultipleLanguages, _, _) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedWaypointInLanguage1 = try await WaypointWaypointModel.createWith(
            title: "Language 2",
            description: "Second description",
            repositoryId: verifiedWaypointRepositoryWithMultipleLanguages.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: true,
            on: app.db
        )
        
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
                XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title)
//                XCTAssertEqual(verifiedWaypoint.location, createdVerifiedWaypoint.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
                let verifiedWaypointInDifferentLanguage = content.items.first { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id }!
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.id, verifiedWaypointRepositoryInDifferentLanguage.id)
                XCTAssertEqual(verifiedWaypointInDifferentLanguage.title, createdVerifiedWaypointInDifferentLanguage.title)
//                XCTAssertEqual(verifiedWaypointInDifferentLanguage.location, createdVerifiedWaypointInDifferentLanguage.location.value)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id })
                let verifiedWaypointWithMultipleLanguages = content.items.first { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id }!
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.id, verifiedWaypointRepositoryWithMultipleLanguages.id)
                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.title, createdVerifiedWaypointInLanguage1.title)
//                XCTAssertEqual(verifiedWaypointWithMultipleLanguages.location, createdVerifiedWaypointInLanguage1.location.value)
                
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
        let (verifiedWaypointRepository, _, _) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        
        // Create a waypoint for a deactivated language
        let (verifiedWaypointRepositoryForDeactivatedLanguage, _, _) = try await createNewWaypoint(verified: true, languageId: deactivatedLanguage.requireID(), userId: userId)
        
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
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.$language.load(on: app.db)
        
        try app
            .describe("Get verified waypoint should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title)
                XCTAssertEqual(content.description, waypoint.description)
                XCTAssertEqual(content.location, location.location)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNil(content.verified)
                XCTAssertNil(content.modelId)
            }
            .test()
    }
    
    func testSuccessfullGetVerifiedWaypointAsModerator() async throws {
        let language = try await createLanguage()
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.$language.load(on: app.db)
        
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Get verified waypoint as moderator should return ok and more details")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title)
                XCTAssertEqual(content.description, waypoint.description)
                XCTAssertEqual(content.location, location.location)
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
        
        let (waypointRepositoryForDeactivatedLanguage, _, _) = try await createNewWaypoint(verified: true, languageId: deactivatedLanguage.requireID())
        
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("Get waypoint for deactivated language should always fail; instead request the model directly")
            .get(waypointsPath.appending(waypointRepositoryForDeactivatedLanguage.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }
    
    func testGetUnverifiedWaypointFails() async throws {
        let (waypointRepository, _, _) = try await createNewWaypoint(verified: false)
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("Get unverified waypoint should return not found")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.notFound)
            .test()
    }
}

