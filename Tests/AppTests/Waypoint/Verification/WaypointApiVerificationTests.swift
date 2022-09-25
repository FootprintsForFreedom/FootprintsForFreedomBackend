//
//  WaypointApiVerificationTests.swift
//  
//
//  Created by niklhut on 13.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiVerificationTests: AppTestCase, WaypointTest {
    func testSuccessfulVerifyWaypoint() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (waypointRepository, waypointModel, location) = try await createNewWaypoint()
        location.verifiedAt = Date()
        try await location.update(on: app.db)
        try await waypointModel.$language.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/verify/\(waypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypointModel.title)
                XCTAssertEqual(content.slug, waypointModel.title.slugify())
                XCTAssertEqual(content.detailText, waypointModel.detailText)
                XCTAssertEqual(content.location, location.location)
                XCTAssertEqual(content.languageCode, waypointModel.language.languageCode)
            }
            .test()
    }
    
    func testVerifyWaypointWithDeactivatedLanguageFails() async throws {
        let language = try await createLanguage()
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint with deactivated language should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/verify/\(waypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testVerifyWaypointAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint()
        
        try app
            .describe("Verify waypoint as user should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/verify/\(waypointModel.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyWaypointWithoutTokenFails() async throws {
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint()
        
        try app
            .describe("Verify waypoint without token should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/verify/\(waypointModel.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyWaypointWithAlreadyVerifiedWaypointFails() async throws {
        let userToken = try await getToken(for: .moderator)
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(verified: true)
        
        try app
            .describe("Verify waypoint for already verified waypoint should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/verify/\(waypointModel.requireID())"))
            .bearerToken(userToken)
            .expect(.badRequest)
            .test()
    }
    
    func testSuccessfulVerifyLocation() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (waypointRepository, waypointModel, locationModel) = try await createNewWaypoint()
        waypointModel.verifiedAt = Date()
        try await waypointModel.update(on: app.db)
        try await waypointModel.$language.load(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successfull and return ok")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/locations/verify/\(locationModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypointModel.title)
                XCTAssertEqual(content.detailText, waypointModel.detailText)
                XCTAssertEqual(content.location, locationModel.location)
                XCTAssertEqual(content.languageCode, waypointModel.language.languageCode)
            }
            .test()
    }
    
    func testVerifyLocationAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        let (waypointRepository, _, locationModel) = try await createNewWaypoint()
        
        try app
            .describe("Verify location as user should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/locations/verify/\(locationModel.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyLocationWithoutTokenFails() async throws {
        let (waypointRepository, _, locationModel) = try await createNewWaypoint()
        
        try app
            .describe("Verify location without token should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/locations/verify/\(locationModel.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyLocationWithAlreadyVerifiedWaypointFails() async throws {
        let userToken = try await getToken(for: .moderator)
        let (waypointRepository, _, locationModel) = try await createNewWaypoint(verified: true)
        
        try app
            .describe("Verify location for already verified waypoint should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/locations/verify/\(locationModel.requireID())"))
            .bearerToken(userToken)
            .expect(.badRequest)
            .test()
    }
}
