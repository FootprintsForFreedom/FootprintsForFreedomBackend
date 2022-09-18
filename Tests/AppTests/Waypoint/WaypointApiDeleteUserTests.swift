//
//  WaypointApiDeleteUserTests.swift
//  
//
//  Created by niklhut on 30.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiDeleteUserTests: AppTestCase, WaypointTest, UserTest {
    func testDeleteUserSetsUserIdToNil() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (user, token) = try await createNewUserWithToken()
        let (waypointRepository, waypoint, location) = try await createNewWaypoint(verifiedAt: Date(), userId: user.requireID())
        try await waypoint.$language.load(on: app.db)
        
        try app
            .describe("User should be able to delete himself; Delete user should set waypoint detail user id to nil")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(token)
            .expect(.noContent)
            .test()
        
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
        
        let updatedDetail = try await WaypointDetailModel.find(waypoint.requireID(), on: app.db)!
        try await updatedDetail.$user.load(on: app.db)
        XCTAssertEqual(updatedDetail.$user.id, nil)
        
        let updatedLocation = try await WaypointLocationModel.find(location.requireID(), on: app.db)!
        try await updatedLocation.$user.load(on: app.db)
        XCTAssertEqual(updatedLocation.$user.id, nil)
    }
}
