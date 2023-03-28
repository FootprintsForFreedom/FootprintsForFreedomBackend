//
//  WaypointApiSuggestTests.swift
//  
//
//  Created by niklhut on 24.10.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiSuggestTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulSuggestWaypointReturnsWhenTextPrefixOfTitle() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        
        try app
            .describe("Suggest waypoint should return the waypoint if it is verified and has the suggest text in the title")
            .get(waypointsPath.appending("suggest/?text=ein&languageCode=\(waypoint.detail.language.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(content.contains { $0.id == waypoint.repository.id })
                guard let suggestedWaypoint = content.first(where: { $0.id == waypoint.repository.id! }) else {
                    XCTFail("Could not find suggested waypoint \(waypoint.repository.id!)")
                    return
                }
                XCTAssertEqual(suggestedWaypoint.title, waypoint.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSuggestWaypointOnlyReturnsVerifiedWaypoints() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: false)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest waypoint should not return the waypoint if it is unverified")
            .get(waypointsPath.appending("suggest/?text=ander&languageCode=\(waypoint.detail.language.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSuggestWaypointDoesNotReturnWhenTextNotInTitle() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest waypoint should not return the waypoint if it is verified but does not have the suggest text in the title or detail text")
            .get(waypointsPath.appending("suggest/?text=anderer&languageCode=\(waypoint.detail.language.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSuggestWaypointOnlyReturnsForSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true, languageId: language.requireID())
        
        try app
            .describe("Suggest waypoint should only return waypoints for the specified language")
            .get(waypointsPath.appending("suggest/?text=ander&languageCode=\(language2.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Waypoint.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSuggestWaypointDoesNotReturnDetailsForDeactivatedLanguage() async throws {
        let language = try await createLanguage()
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true, languageId: language.requireID())
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest waypoint should only return waypoints for the specified language")
            .get(waypointsPath.appending("suggest/?text=ander&languageCode=\(language.languageCode)"))
            .expect(.notFound)
            .test()
    }
    
    func testSuggestWaypointNeedsValidText() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest waypoint should return the text query field is empty")
            .get(waypointsPath.appending("suggest/?text=&languageCode=\(waypoint.detail.language.languageCode)"))
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Suggest waypoint should return the text query field is only a whitespace or a newline")
            .get(waypointsPath.appending("suggest/?text=%20\n&languageCode=\(waypoint.detail.language.languageCode)"))
            .expect(.badRequest)
            .test()
    }
    
    func testSuggestWaypointNeedsValidLanguageCode() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest waypoint should return the text query field is empty")
            .get(waypointsPath.appending("suggest/?text=bes"))
            .expect(.badRequest)
            .test()
    }
}
