//
//  WaypointApiDeleteTests.swift
//  
//
//  Created by niklhut on 19.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiDeleteTests: AppTestCase, WaypointTest {
    func testSuccessfulDeleteUnverifiedWaypointAsModerator() async throws {
        // Get original waypoint count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        let (waypointRepository, _, _) = try await createNewWaypoint()
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete a unverified waypoint")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
    }
    
    func testSuccessfulDeleteVerifiedWaypointAsModerator() async throws {
        // Get original waypoint count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        let (waypointRepository, _, _) = try await createNewWaypoint(verifiedAt: Date())
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete a verified waypoint")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
    }
    
    func testDeleteWaypointRepositoryDeletesModels() async throws {
        // Get original waypoint repository and model count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let waypointModelCount = try await WaypointDetailModel.query(on: app.db).count()
        let locationCount = try await WaypointLocationModel.query(on: app.db).count()
        
        let (waypointRepository, _, _) = try await createNewWaypoint(verifiedAt: Date())
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete a verified waypoint")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let newWaypointModelCount = try await WaypointDetailModel.query(on: app.db).count()
        let newLocationCount = try await WaypointLocationModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
        XCTAssertEqual(newWaypointModelCount, waypointModelCount)
        XCTAssertEqual(newLocationCount, locationCount)
        
        // TODO: confirm this is also the case after updates
    }
    
    func testDeleteUnverifiedWaypointAsCreatorFails() async throws {
        let user = try await getUser(role: .user)
        let userToken = try user.generateToken()
        try await userToken.create(on: app.db)
        let (waypointRepository, _, _) = try await createNewWaypoint(userId: user.requireID())
        
        try app
            .describe("A user should not be able to delete a waypoint")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(userToken.value)
            .expect(.forbidden)
            .test()
    }
    
    
    func testDeleteWaypointAsUserFails() async throws {
        let (waypointRepository, _, _) = try await createNewWaypoint()
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("A user should not be able to delete a waypoint")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteWihtoutTokenFails() async throws {
        let (waypointRepository, _, _) = try await createNewWaypoint()
        
        try app
            .describe("Delete waypoint without token fails")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingWaypointFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Delete nonexistent waypoint fails")
            .delete(waypointsPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
}

extension WaypointApiDeleteTests {
    func testDelteWaypointDeletesReports() async throws {
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let reportCount = try await WaypointReportModel.query(on: app.db).count()
        
        let waypoint = try await createNewWaypoint()
        let title = "I don't like this \(UUID())"
        let report = try await WaypointReportModel(
            verifiedAt: nil,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: waypoint.detail.requireID(),
            repositoryId: waypoint.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        try await waypoint.repository.delete(force: true, on: app.db)
        
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let newReportCount = try await WaypointReportModel.query(on: app.db).count()
        
        XCTAssertEqual(waypointCount, newWaypointCount)
        XCTAssertEqual(reportCount, newReportCount)
    }
}
