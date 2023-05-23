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

final class WaypointApiGetTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulListVerifiedWaypointsWithPreferredLanguageReturnsVerifiedModelsForAllLanguagesButPrefersSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint, createdVerifiedLocation) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedWaypoint.$language.load(on: app.db)
        // Create a second not verified model for the verified waypoint that should not be returned
        let _ = try await WaypointDetailModel.createWith(
            title: "Not visible \(UUID())",
            detailText: "Not visible",
            repositoryId: verifiedWaypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: false,
            on: self
        )
        // Create a repository that is only available in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, createdVerifiedWaypointInDifferentLanguage, createdVerifiedLocationInDifferentLanguage) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedWaypointInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedWaypointRepositoryWithMultipleLanguages, _, verifiedWaypointRepositoryWithMultipleLanguagesLocation) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedWaypointInLanguage1 = try await WaypointDetailModel.createWith(
            title: "Language 2 \(UUID())",
            detailText: "Second detailText",
            repositoryId: verifiedWaypointRepositoryWithMultipleLanguages.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: true,
            on: self
        )
        try await createdVerifiedWaypointInLanguage1.$language.load(on: app.db)
        
        // Get verified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .with(\.$locations)
            .all()
        
        let waypointCount = waypoints.count
        
        let verifiedWaypointCount = waypoints
            .filter { $0.details.contains { $0.verifiedAt != nil && $0.language.priority != nil } && $0.locations.contains { $0.verifiedAt != nil } }
            .count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List waypoints with perferred language should return ok and verified models for all languages. However, it should prefer the specified language")
            .get(waypointsPath.appending("?preferredLanguage=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.ListWrapper.self) { wrapper in
                let content = wrapper.items
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, verifiedWaypointCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, verifiedWaypointCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                if let verifiedWaypoint = content.items.first(where: { $0.id == verifiedWaypointRepository.id }) {
                    XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                    XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title)
                    XCTAssertEqual(verifiedWaypoint.location, createdVerifiedLocation.location)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
                if let verifiedWaypointInDifferentLanguage = content.items.first(where: { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id }) {
                    XCTAssertEqual(verifiedWaypointInDifferentLanguage.id, verifiedWaypointRepositoryInDifferentLanguage.id)
                    XCTAssertEqual(verifiedWaypointInDifferentLanguage.title, createdVerifiedWaypointInDifferentLanguage.title)
                    XCTAssertEqual(verifiedWaypointInDifferentLanguage.location, createdVerifiedLocationInDifferentLanguage.location)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id })
                if let verifiedWaypointWithMultipleLanguages = content.items.first(where: { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id }) {
                    XCTAssertEqual(verifiedWaypointWithMultipleLanguages.id, verifiedWaypointRepositoryWithMultipleLanguages.id)
                    XCTAssertEqual(verifiedWaypointWithMultipleLanguages.title, createdVerifiedWaypointInLanguage1.title)
                    XCTAssertEqual(verifiedWaypointWithMultipleLanguages.location, verifiedWaypointRepositoryWithMultipleLanguagesLocation.location)
                }
                
                XCTAssert(!content.items.contains { $0.id == unverifiedWaypointRepository.id })
            }
            .test()
    }
    
    func testSuccessfulListVerifiedWaypointsWithoutPreferredLanguageReturnsVerifiedModlesForAllLanguagesAccordingToTheirPriority() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, _, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint, createdVerifiedLocation) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified waypoint that should not be returned
        let _ = try await WaypointDetailModel.createWith(
            title: "Not visible \(UUID())",
            detailText: "Not visible",
            repositoryId: verifiedWaypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: false,
            on: self
        )
        // Create a repository that is only available in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, createdVerifiedWaypointInDifferentLanguage, createdVerifiedLocationInDifferentLanguage) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedWaypointInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedWaypointRepositoryWithMultipleLanguages, _, verifiedWaypointRepositoryWithMultipleLanguagesLocation) = try await createNewWaypoint(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedWaypointInLanguage1 = try await WaypointDetailModel.createWith(
            title: "Language 2 \(UUID())",
            detailText: "Second detailText",
            repositoryId: verifiedWaypointRepositoryWithMultipleLanguages.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: true,
            on: self
        )
        
        // Get verified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .with(\.$locations)
            .all()
        
        let waypointCount = waypoints.count
        
        let verifiedWaypointCount = waypoints
            .filter { $0.details.contains { $0.verifiedAt != nil && $0.language.priority != nil } && $0.locations.contains { $0.verifiedAt != nil } }
            .count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List waypoints should return ok")
            .get(waypointsPath.appending("?per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.ListWrapper.self) { wrapper in
                let content = wrapper.items
                XCTAssertEqual(content.items.count, verifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                if let verifiedWaypoint = content.items.first(where: { $0.id == verifiedWaypointRepository.id }) {
                    XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                    XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title)
                    XCTAssertEqual(verifiedWaypoint.location, createdVerifiedLocation.location)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
                if let verifiedWaypointInDifferentLanguage = content.items.first(where: { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id }) {
                    XCTAssertEqual(verifiedWaypointInDifferentLanguage.id, verifiedWaypointRepositoryInDifferentLanguage.id)
                    XCTAssertEqual(verifiedWaypointInDifferentLanguage.title, createdVerifiedWaypointInDifferentLanguage.title)
                    XCTAssertEqual(verifiedWaypointInDifferentLanguage.location, createdVerifiedLocationInDifferentLanguage.location)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id })
                if let verifiedWaypointWithMultipleLanguages = content.items.first(where: { $0.id == verifiedWaypointRepositoryWithMultipleLanguages.id }) {
                    XCTAssertEqual(verifiedWaypointWithMultipleLanguages.id, verifiedWaypointRepositoryWithMultipleLanguages.id)
                    XCTAssertEqual(verifiedWaypointWithMultipleLanguages.title, createdVerifiedWaypointInLanguage1.title)
                    XCTAssertEqual(verifiedWaypointWithMultipleLanguages.location, verifiedWaypointRepositoryWithMultipleLanguagesLocation.location)
                }
                
                XCTAssert(!content.items.contains { $0.id == unverifiedWaypointRepository.id })
            }
            .test()
    }
    
    func testSuccessfulListVerifiedWaypointsDoesNotReturnModelsForDeactivatedLanguages() async throws {
        let language = try await createLanguage()
        let deactivatedLanguage = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create a verified waypoint
        let (verifiedWaypointRepository, _, _) = try await createNewWaypoint(verified: true, languageId: language.requireID(), userId: userId)
        
        // Create a waypoint for a deactivated language
        let (verifiedWaypointRepositoryForDeactivatedLanguage, _, _) = try await createNewWaypoint(verified: true, languageId: deactivatedLanguage.requireID(), userId: userId)
        print(try verifiedWaypointRepositoryForDeactivatedLanguage.requireID())
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        // Get waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .all()
        
        let waypointCount = waypoints.count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List waypoints should return ok")
            .get(waypointsPath.appending("?per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.ListWrapper.self) { wrapper in
                let content = wrapper.items
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                XCTAssertFalse(content.items.contains { $0.id == verifiedWaypointRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }
    
    // TODO: if unverified, require user to be creator or moderator
    // but there is no creator?!
    func testSuccessfulGetVerifiedWaypoint() async throws {
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verified: true)
        try await waypoint.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified waypoint should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title)
                XCTAssertEqual(content.slug, waypoint.slug)
                XCTAssertEqual(content.detailText, waypoint.detailText)
                XCTAssertEqual(content.location, location.location)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedWaypointWithTags() async throws {
        let language = try await createLanguage()
        let tag = try await createNewTag(verified: true, languageId: language.requireID())
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypointRepository.$tags.attach(tag.repository, on: app.db)
        try await waypoint.$language.load(on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified waypoint should return ok")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title)
                XCTAssertEqual(content.slug, waypoint.slug)
                XCTAssertEqual(content.detailText, waypoint.detailText)
                XCTAssertEqual(content.location, location.location)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }

    
    func testSuccessfulGetVerifiedWaypointAsModerator() async throws {
        let language = try await createLanguage()
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified waypoint as moderator should return ok and more details")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title)
                XCTAssertEqual(content.detailText, waypoint.detailText)
                XCTAssertEqual(content.location, location.location)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, waypoint.id!)
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedWaypointBySlug() async throws {
        let language = try await createLanguage()
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified waypoint by slug should return ok")
            .get(waypointsPath.appending("find/\(waypoint.slug)"))
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypoint.title)
                XCTAssertEqual(content.slug, waypoint.slug)
                XCTAssertEqual(content.detailText, waypoint.detailText)
                XCTAssertEqual(content.location, location.location)
                XCTAssertEqual(content.languageCode, waypoint.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertNotNil(content.locationId)
            }
            .test()
    }
    
    func testGetWaypointForDeactivatedLanguageFails() async throws {
        let deactivatedLanguage = try await createLanguage()
        let (waypointRepositoryForDeactivatedLanguage, _, _) = try await createNewWaypoint(verified: true, languageId: deactivatedLanguage.requireID())
        
        let adminToken = try await getToken(for: .admin)
        
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try await Task.sleep(for: .seconds(1))
        
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
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get unverified waypoint should return not found")
            .get(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.notFound)
            .test()
    }
}

