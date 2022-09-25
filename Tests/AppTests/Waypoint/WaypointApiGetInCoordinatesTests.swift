//
//  WaypointApiGetInCoordinatesTests.swift
//  
//
//  Created by niklhut on 13.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiGetInCoordinatesTests: AppTestCase, WaypointTest {
    func testSuccessfulGetWaypointsInCoordinates() async throws {
        let waypoint = try await createNewWaypoint(verified: true)
        
        let getInRangeContent = WaypointApiController.GetInRangeQuery(
            tepLeftLatitude: waypoint.location.latitude + 1,
            tepLeftLongitude: waypoint.location.longitude + 1,
            bottomRightLatitude: waypoint.location.latitude - 1,
            bottomRightLongitude: waypoint.location.longitude - 1
        )
        
        let query = try URLEncodedFormEncoder().encode(getInRangeContent)
        
        try app
            .describe("Successful get waypoints in coordinate range should return all waypoints in this coordinate range")
            .get(waypointsPath.appending("in/?\(query)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(content.contains { $0.id == waypoint.repository.id! })
            }
            .test()
    }
    
    func testSuccessfulGetWaypointsInCoordinatesDoesNotReturnUnverifiedLocation() async throws {
        let waypoint = try await createNewWaypoint()
        waypoint.detail.verifiedAt = Date()
        try await waypoint.detail.update(on: app.db)
        
        let getInRangeContent = WaypointApiController.GetInRangeQuery(
            tepLeftLatitude: waypoint.location.latitude + 1,
            tepLeftLongitude: waypoint.location.longitude + 1,
            bottomRightLatitude: waypoint.location.latitude - 1,
            bottomRightLongitude: waypoint.location.longitude - 1
        )
        
        let query = try URLEncodedFormEncoder().encode(getInRangeContent)
        
        try app
            .describe("Successful get waypoints in coordinate range should return all waypoints in this coordinate range")
            .get(waypointsPath.appending("in/?\(query)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == waypoint.repository.id! })
            }
            .test()
    }
    
    func testSuccessfulGetWaypointsInCoordinatesDoesNotReturnUnverifiedDetail() async throws {
        let waypoint = try await createNewWaypoint()
        waypoint.location.verifiedAt = Date()
        try await waypoint.detail.update(on: app.db)
        
        let getInRangeContent = WaypointApiController.GetInRangeQuery(
            tepLeftLatitude: waypoint.location.latitude + 1,
            tepLeftLongitude: waypoint.location.longitude + 1,
            bottomRightLatitude: waypoint.location.latitude - 1,
            bottomRightLongitude: waypoint.location.longitude - 1
        )
        
        let query = try URLEncodedFormEncoder().encode(getInRangeContent)
        
        try app
            .describe("Successful get waypoints in coordinate range should return all waypoints in this coordinate range")
            .get(waypointsPath.appending("in/?\(query)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == waypoint.repository.id! })
            }
            .test()
    }
}
