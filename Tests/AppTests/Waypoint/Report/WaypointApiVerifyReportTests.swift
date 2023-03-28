//
//  WaypointApiVerifyReportTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiVerifyReportTests: AppTestCase, WaypointTest {
    func testSuccessfulVerifyReport() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Report.Detail<Waypoint.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, report.title)
                XCTAssertContains(content.slug, report.title.slugify())
                XCTAssertEqual(content.reason, report.reason)
                XCTAssertNotNil(content.visibleDetail)
                if let visibleDetail = content.visibleDetail {
                    XCTAssertEqual(visibleDetail.id, waypoint.repository.id)
                    XCTAssertEqual(visibleDetail.title, waypoint.detail.title)
                    XCTAssertEqual(visibleDetail.slug, waypoint.detail.slug)
                    XCTAssertEqual(visibleDetail.detailText, waypoint.detail.detailText)
                    XCTAssertEqual(visibleDetail.location, waypoint.location.location)
                    XCTAssertEqual(visibleDetail.languageCode, waypoint.detail.language.languageCode)
                    XCTAssertNotNil(visibleDetail.detailId)
                    XCTAssertNotNil(visibleDetail.locationId)
                }
            }
            .test()
    }
    
    func testSuccessfulVerifyReportWithDeletedVisbleDetail() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint)
        try await waypoint.detail.delete(force: true, on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Report.Detail<Waypoint.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, report.title)
                XCTAssertContains(content.slug, report.title.slugify())
                XCTAssertEqual(content.reason, report.reason)
                XCTAssertNil(content.visibleDetail)
            }
            .test()
    }
    
    func testVerifyReportAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as user should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyReportWithoutTokenFails() async throws {
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report without token should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports/verify/\(report.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyReportWithAlreadyVerifiedReportFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let waypoint = try await createNewWaypoint()
        let report = try await createNewWaypointReport(waypoint: waypoint, verifiedAt: Date())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
