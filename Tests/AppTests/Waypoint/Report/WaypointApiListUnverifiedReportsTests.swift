//
//  WaypointApiListUnverifiedReportsTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiListUnverifiedReportsTests: AppTestCase, WaypointTest {
    func testSuccessfulListUnverifiedReportsListsUnverifiedReports() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint)
        let reportsCount = try await WaypointReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports should return unverified reports")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Report.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == report.id })
            }
            .test()
    }
    
    func testSuccessfulListUnverifiedReportsDoesNotListVerifiedReports() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint, verifiedAt: Date())
        let reportsCount = try await WaypointReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports should not return verified reports")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Report.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == report.id })
            }
            .test()
    }
    
    func testListUnverifiedReportsAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let waypoint = try await createNewWaypoint()
        let _ = try await createNewWaypointReport(waypoint: waypoint)
        let reportsCount = try await WaypointReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports as user should fail")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedReportsWithoutTokenFails() async throws {
        let waypoint = try await createNewWaypoint()
        let _ = try await createNewWaypointReport(waypoint: waypoint)
        let reportsCount = try await WaypointReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports without token should fail")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .expect(.unauthorized)
            .test()
    }
}
