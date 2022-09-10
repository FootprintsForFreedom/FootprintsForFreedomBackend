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

final class WaypointApiListUnverifiedTests: AppTestCase, WaypointTest {
    func testSuccessfulListRepositoriesWithUnverifiedModels() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (unverifiedWaypointRepository, createdUnverifiedWaypoint, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        // Create a verified waypoint
        let (verifiedWaypointRepository, createdVerifiedWaypoint, _) = try await createNewWaypoint(verifiedAt: Date(), languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified waypoint
        let _ = try await WaypointDetailModel.createWith(
            title: "Not visible \(UUID())",
            detailText: "Not visible",
            repositoryId: verifiedWaypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verifiedAt: nil,
            on: app.db
        )
        // Create a waypoint in the other language
        let (verifiedWaypointRepositoryInDifferentLanguage, _, _) = try await createNewWaypoint(verifiedAt: Date(), languageId: language2.requireID(), userId: userId)
        
        // Get unverified waypoint count
        let waypoints = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .with(\.$tags.$pivots)
            .all()
        
        let waypointCount = waypoints.count
        
        let unverifiedWaypointCount = waypoints
            .filter { $0.details.contains { $0.verifiedAt == nil && $0.language.priority != nil} || $0.$tags.pivots.contains { [Status.pending, .deleteRequested].contains($0.status) }}
            .count
        
        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(waypointsPath.appending("unverified/?preferredLanguage=\(language.languageCode)&per=\(waypointCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedWaypointCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, unverifiedWaypointCount)
                XCTAssert(content.items.map { $0.id }.uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedWaypointCount)
                
                XCTAssert(content.items.contains { $0.id == unverifiedWaypointRepository.id })
                if let unverifiedWaypoint = content.items.first(where: { $0.id == unverifiedWaypointRepository.id }) {
                    XCTAssertEqual(unverifiedWaypoint.id, unverifiedWaypointRepository.id)
                    XCTAssertEqual(unverifiedWaypoint.title, createdUnverifiedWaypoint.title)
                    //                XCTAssertEqual(unverifiedWaypoint.location, createdUnverifiedWaypoint.location.value)
                }
                
                
                // contains the verified waypoint repository because it has a second unverified waypoint model
                // here it should also return the verified model in the list for preview to see which waypoint was edited
                XCTAssert(content.items.contains { $0.id == verifiedWaypointRepository.id })
                if let verifiedWaypoint = content.items.first(where: { $0.id == verifiedWaypointRepository.id }) {
                    XCTAssertEqual(verifiedWaypoint.id, verifiedWaypointRepository.id)
                    XCTAssertEqual(verifiedWaypoint.title, createdVerifiedWaypoint.title)
                    //                XCTAssertEqual(verifiedWaypoint.location, createdVerifiedWaypoint.location.value)
                }
                
                XCTAssertFalse(content.items.contains { $0.id == verifiedWaypointRepositoryInDifferentLanguage.id })
            }
            .test()
    }
    
    func testListRepositoriesWithUnverifiedModelsAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("List repositories with unverified models as user should fail")
            .get(waypointsPath.appending("unverified"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListRepositoriesWithUnverifiedModelsWithoutTokenFails() async throws {
        try app
            .describe("List repositories with unverified models without token should fail")
            .get(waypointsPath.appending("unverified"))
            .expect(.unauthorized)
            .test()
    }
    
    func testSuccessfulListUnverifiedWaypointsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified waypoint
        let (waypointRepository, createdUnverifiedWaypoint, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedWaypoint.$language.load(on: app.db)
        // Create a verified waypoint for the same repository
        let verifiedWaypoint = try await WaypointDetailModel.createWith(
            title: "Verified Waypoint \(UUID())",
            detailText: "This is text",
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verifiedAt: Date(),
            on: app.db
        )
        // Create a second not verified waypoint for the same repository
        let secondCreatedUnverifiedWaypoint = try await WaypointDetailModel.createWith(
            title: "Not visible \(UUID())",
            detailText: "Not visible",
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verifiedAt: nil,
            on: app.db
        )
        try await secondCreatedUnverifiedWaypoint.$language.load(on: app.db)
        // Create a second not verified waypoint for the same repository in another language
        let createdUnverifiedWaypointInDifferentLanguage = try await WaypointDetailModel.createWith(
            title: "Different Language \(UUID())",
            detailText: "Not visible, other language",
            repositoryId: waypointRepository.requireID(),
            languageId: language2.requireID(),
            userId: userId,
            verifiedAt: nil,
            on: app.db
        )
        try await createdUnverifiedWaypointInDifferentLanguage.$language.load(on: app.db)
        // Create a not verified waypoint for another repository
        let (_, unverifiedWaypointForDifferentRepository, _) = try await createNewWaypoint(languageId: language.requireID(), userId: userId)
        
        // Get unverified and verified waypoint count
        let waypointCount = try await WaypointDetailModel
            .query(on: app.db)
            .count()
        
        let unverifiedWaypointForRepositoryCount = try await WaypointDetailModel
            .query(on: app.db)
            .filter(\.$verifiedAt == nil)
            .filter(\.$repository.$id == waypointRepository.requireID())
            .count()
        
        try app
            .describe("List unverified waypoints should return ok and unverified models for all languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/unverified/?per=\(waypointCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Repository.ListUnverifiedWaypoints>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedWaypointForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.detailId }.uniqued().count, unverifiedWaypointForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.detailId }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedWaypointForRepositoryCount)
                
                XCTAssert(content.items.contains { $0.detailId == createdUnverifiedWaypoint.id })
                if let unverifiedWaypoint = content.items.first(where: { $0.detailId == createdUnverifiedWaypoint.id }) {
                    XCTAssertEqual(unverifiedWaypoint.detailId, createdUnverifiedWaypoint.id)
                    XCTAssertEqual(unverifiedWaypoint.title, createdUnverifiedWaypoint.title)
                    XCTAssertEqual(unverifiedWaypoint.detailText, createdUnverifiedWaypoint.detailText)
                    XCTAssertEqual(unverifiedWaypoint.languageCode, createdUnverifiedWaypoint.language.languageCode)
                }
                
                XCTAssertFalse(content.items.contains { $0.detailId == verifiedWaypoint.id })
                
                XCTAssert(content.items.contains { $0.detailId == secondCreatedUnverifiedWaypoint.id })
                if let secondUnverifiedWaypoint = content.items.first(where: { $0.detailId == secondCreatedUnverifiedWaypoint.id }) {
                    XCTAssertEqual(secondUnverifiedWaypoint.detailId, secondCreatedUnverifiedWaypoint.id)
                    XCTAssertEqual(secondUnverifiedWaypoint.title, secondCreatedUnverifiedWaypoint.title)
                    XCTAssertEqual(secondUnverifiedWaypoint.detailText, secondCreatedUnverifiedWaypoint.detailText)
                    XCTAssertEqual(secondUnverifiedWaypoint.languageCode, secondCreatedUnverifiedWaypoint.language.languageCode)
                }
                
                XCTAssert(content.items.contains { $0.detailId == createdUnverifiedWaypointInDifferentLanguage.id })
                if let unverifiedWaypointInDifferentLanguage = content.items.first(where: { $0.detailId == createdUnverifiedWaypointInDifferentLanguage.id }) {
                    XCTAssertEqual(unverifiedWaypointInDifferentLanguage.detailId, createdUnverifiedWaypointInDifferentLanguage.id)
                    XCTAssertEqual(unverifiedWaypointInDifferentLanguage.title, createdUnverifiedWaypointInDifferentLanguage.title)
                    XCTAssertEqual(unverifiedWaypointInDifferentLanguage.detailText, createdUnverifiedWaypointInDifferentLanguage.detailText)
                    XCTAssertEqual(unverifiedWaypointInDifferentLanguage.languageCode, createdUnverifiedWaypointInDifferentLanguage.language.languageCode)
                }
                
                XCTAssertFalse(content.items.contains { $0.detailId == unverifiedWaypointForDifferentRepository.id })
            }
            .test()
    }
    
    func testListUnverifiedWaypointsForRepositoryAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        // Create an unverified waypoint
        let (waypointRepository, _, _) = try await createNewWaypoint()
        
        try app
            .describe("List unverified waypoints as user should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/unverified/"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedWaypointsForRepositoryWithoutTokenFails() async throws {
        // Create an unverified waypoint
        let (waypointRepository, _, _) = try await createNewWaypoint()
        
        try app
            .describe("List unverified waypoints wihtout token should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/unverified/"))
            .expect(.unauthorized)
            .test()
    }
    
    func testSuccessfulListUnverifiedLocationsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified location
        let (waypointRepository, _, createdUnverifiedLocation) = try await createNewWaypoint(userId: userId)
        // Create a verified location for the same repository
        let verifiedLocation = try await WaypointLocationModel.createWith(
            location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
            repositoryId: waypointRepository.requireID(),
            userId: userId,
            verifiedAt: Date(),
            on: app.db
        )
        // Create a second not verified location for the same repository
        let secondCreatedUnverifiedLocation = try await WaypointLocationModel.createWith(
            location: .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
            repositoryId: waypointRepository.requireID(),
            userId: userId,
            verifiedAt: nil,
            on: app.db
        )
        // Create a not verified location for another repository
        let (_, _, unverifiedLocationForDifferentRepository) = try await createNewWaypoint(userId: userId)
        
        // Get unverified and verified location count
        let locationCount = try await WaypointLocationModel
            .query(on: app.db)
            .count()
        
        let unverifiedLocationForRepositoryCount = try await WaypointLocationModel
            .query(on: app.db)
            .filter(\.$verifiedAt == nil)
            .filter(\.$repository.$id == waypointRepository.requireID())
            .count()
        
        try app
            .describe("List unverified locations should return ok and unverified models for all languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/locations/unverified/?per=\(locationCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Repository.ListUnverifiedLocations>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedLocationForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.locationId }.uniqued().count, unverifiedLocationForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.locationId }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedLocationForRepositoryCount)
                
                XCTAssert(content.items.contains { $0.locationId == createdUnverifiedLocation.id })
                if let unverifiedWaypoint = content.items.first(where: { $0.locationId == createdUnverifiedLocation.id }) {
                    XCTAssertEqual(unverifiedWaypoint.locationId, createdUnverifiedLocation.id)
                    XCTAssertEqual(unverifiedWaypoint.location, createdUnverifiedLocation.location)
                }
                
                XCTAssertFalse(content.items.contains { $0.locationId == verifiedLocation.id })
                
                XCTAssert(content.items.contains { $0.locationId == secondCreatedUnverifiedLocation.id })
                if let secondUnverifiedWaypoint = content.items.first(where: { $0.locationId == secondCreatedUnverifiedLocation.id }) {
                    XCTAssertEqual(secondUnverifiedWaypoint.locationId, secondCreatedUnverifiedLocation.id)
                    XCTAssertEqual(secondUnverifiedWaypoint.location, secondCreatedUnverifiedLocation.location)
                }
                
                XCTAssertFalse(content.items.contains { $0.locationId == unverifiedLocationForDifferentRepository.id })
            }
            .test()
    }
    
    func testListUnverifiedLocationsForReposiotryAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        // Create an unverified waypoint
        let (waypointRepository, _, _) = try await createNewWaypoint()
        
        try app
            .describe("List unverified locations as user should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/locations/unverified/"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedLocationsForReposiotryWithoutTokenFails() async throws {
        // Create an unverified waypoint
        let (waypointRepository, _, _) = try await createNewWaypoint()
        
        try app
            .describe("List unverified locations wihtout token should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/locations/unverified/"))
            .expect(.unauthorized)
            .test()
    }
}
