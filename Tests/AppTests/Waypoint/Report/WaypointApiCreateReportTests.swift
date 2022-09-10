//
//  WaypointApiCreateReportTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiCreateReportTests: AppTestCase, WaypointTest {
    func getWaypointReportCreateContent(
        title: String = "I don't like this",
        reason: String = "Just because",
        visibleDetailId: UUID
    ) -> Report.Create {
        return .init(title: title, reason: reason, visibleDetailId: visibleDetailId)
    }
    
    func testSuccessfulCreateReport() async throws {
        let token = try await getToken(for: .user, verified: true)
        let waypoint = try await createNewWaypoint()
        let newReport = getWaypointReportCreateContent(visibleDetailId: try waypoint.detail.requireID())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Create new report as verified user should return ok")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.created)
            .expect(.json)
            .expect(Report.Detail<Waypoint.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, newReport.title)
                XCTAssertContains(content.slug, newReport.title.slugify())
                XCTAssertEqual(content.reason, newReport.reason)
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
    
    func testCreateReportAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let waypoint = try await createNewWaypoint()
        let newReport = getWaypointReportCreateContent(visibleDetailId: try waypoint.detail.requireID())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Create new report as unverified user should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateReportWithoutTokenFails() async throws {
        let waypoint = try await createNewWaypoint()
        let newReport = getWaypointReportCreateContent(visibleDetailId: try waypoint.detail.requireID())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Create new report without token should fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports"))
            .body(newReport)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateReportNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let waypoint = try await createNewWaypoint()
        let newReport = getWaypointReportCreateContent(title: "", visibleDetailId: try waypoint.detail.requireID())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Create new report should require valid title and fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateReportNeedsValidReason() async throws {
        let token = try await getToken(for: .user, verified: true)
        let waypoint = try await createNewWaypoint()
        let newReport = getWaypointReportCreateContent(reason: "", visibleDetailId: try waypoint.detail.requireID())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Create new report should require valid reason and fail")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateReportNeedsValidVisibleDetailId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let waypoint = try await createNewWaypoint()
        let waypoint2 = try await createNewWaypoint()
        let newReport = getWaypointReportCreateContent(visibleDetailId: try waypoint.detail.requireID())
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Create new report should require valid visible detail id and fail")
            .post(waypointsPath.appending("\(waypoint2.repository.requireID())/reports"))
            .body(newReport)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
