//
//  WaypointApiSearchTests.swift
//  
//
//  Created by niklhut on 05.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiSearchTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulSearchWaypointReturnsWhenTextInTitle() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        
        try app
            .describe("Search waypoint should return the waypoint if it is verified and has the search text in the title")
            .get(waypointsPath.appending("search/?text=besonderer&languageCode=\(waypoint.detail.language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
                guard let searchedWaypoint = content.items.first(where: { $0.id == waypoint.repository.id! }) else {
                    XCTFail("Could not find searched waypoint \(waypoint.repository.id!)")
                    return
                }
                XCTAssertEqual(searchedWaypoint.title, waypoint.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointReturnsWhenTextInDetailText() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        
        try app
            .describe("Search waypoint should return the waypoint if it is verified and has the search text in the detail text")
            .get(waypointsPath.appending("search/?text=anderer&languageCode=\(waypoint.detail.language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
                guard let searchedWaypoint = content.items.first(where: { $0.id == waypoint.repository.id! }) else {
                    XCTFail("Could not find searched waypoint \(waypoint.repository.id!)")
                    return
                }
                XCTAssertEqual(searchedWaypoint.title, waypoint.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointOnlyReturnsVerifiedWaypoints() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: false)
        try await waypoint.detail.$language.load(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should not return the waypoint if it is unverified")
            .get(waypointsPath.appending("search/?text=ander&languageCode=\(waypoint.detail.language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointDoesNotReturnWhenTextNotInTitleOrDetailText() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should not return the waypoint if it is verified but does not have the search text in the title or detail text")
            .get(waypointsPath.appending("search/?text=hallo&languageCode=\(waypoint.detail.language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointReturnsWhenTextInTagTitle() async throws {
        let language = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        let waypoint = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.repository.$tags.attach(tag.repository, on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        
        try app
            .describe("Search waypoint should return the waypoint if it is verified and has the search text in a connected tag title")
            .get(waypointsPath.appending("search/?text=besonderer&languageCode=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
                guard let searchedWaypoint = content.items.first(where: { $0.id == waypoint.repository.id }) else {
                    XCTFail("Could not find searched waypoint")
                    return
                }
                XCTAssertEqual(searchedWaypoint.title, waypoint.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointReturnsWhenTextInTagKeywords() async throws {
        let language = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        let waypoint = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.repository.$tags.attach(tag.repository, on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        
        try app
            .describe("Search waypoint should return the waypoint if it is verified and has the search text in a connected tag keyword")
            .get(waypointsPath.appending("search/?text=anders&languageCode=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
                guard let searchedWaypoint = content.items.first(where: { $0.id == waypoint.repository.id }) else {
                    XCTFail("Could not find searched waypoint")
                    return
                }
                XCTAssertEqual(searchedWaypoint.title, waypoint.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchOnlySearchesNewestVerifiedVersionOfTag() async throws {
        let language = try await createLanguage()
        let userId = try await getUser(role: .user).requireID()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        let _ = try await TagDetailModel.createWith(
            verified: true,
            title: "Das wird nicht gefunden",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: userId,
            on: self
        )
        
        let waypoint = try await createNewWaypoint(verified: true, languageId: language.requireID())
        try await waypoint.repository.$tags.attach(tag.repository, on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should only search the newest version of a connected tag")
            .get(waypointsPath.appending("search/?text=er&languageCode=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchOnlySearchesTagsInSpecifiedLanguage() async throws {
        let otherLanguage = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: otherLanguage.requireID())
        let waypoint = try await createNewWaypoint(verified: true)
        try await waypoint.repository.$tags.attach(tag.repository, on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should only search tag details in the specified language")
            .get(waypointsPath.appending("search/?text=er&languageCode=\(otherLanguage.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointOnlyReturnsDetailsForSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true, languageId: language.requireID())
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should only return waypoints for the specified language")
            .get(waypointsPath.appending("search/?text=ander&languageCode=\(language2.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchWaypointDoesNotReturnDetailsForDeactivatedLanguage() async throws {
        let language = try await createLanguage()
        let _ = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true, languageId: language.requireID())
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should only return waypoints for the specified language")
            .get(waypointsPath.appending("search/?text=ander&languageCode=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.notFound)
            .test()
    }
    
    func testSuccessfulSearchWaypointOnlyReturnsNewestVerifiedDetailForRepository() async throws {
        let language = try await createLanguage()
        let userId = try await getUser(role: .user).requireID()
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true, languageId: language.requireID())
        let newerWaypoint = try await WaypointDetailModel.createWith(
            title: "Ein besonderer Titel \(UUID()) neu",
            detailText: "Ein neuer anderer Text",
            repositoryId: waypoint.repository.requireID(),
            languageId: language.requireID(),
            userId: userId,
            verified: true,
            on: self
        )
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(nanoseconds: UInt64(1 * Double(NSEC_PER_SEC)))
        
        try app
            .describe("Search waypoint should only return the newest verified detail for a waypoint repository")
            .get(waypointsPath.appending("search/?text=besonderer&languageCode=\(language.languageCode)&per=\(waypointCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
                guard let searchedWaypoint = content.items.first(where: { $0.id == waypoint.repository.id }) else {
                    XCTFail("Could not find searched waypoint")
                    return
                }
                XCTAssertEqual(searchedWaypoint.title, newerWaypoint.title)
                XCTAssertNotEqual(searchedWaypoint.title, waypoint.detail.title)
                XCTAssert(!content.items.contains(where: { $0.title == waypoint.detail.title }))
                XCTAssert(content.items.contains(where: { $0.title == newerWaypoint.title }))
            }
            .test()
    }
    
    func testSearchWaypointNeedsValidText() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should return the text query field is empty")
            .get(waypointsPath.appending("search/?text=&languageCode=\(waypoint.detail.language.languageCode)&per=\(waypointCount)"))
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Search waypoint should return the text query field is only a whitespace or a newline")
            .get(waypointsPath.appending("search/?text=%20\n&languageCode=\(waypoint.detail.language.languageCode)&per=\(waypointCount)"))
            .expect(.badRequest)
            .test()
    }
    
    func testSearchWaypointNeedsValidLanguageCode() async throws {
        let waypoint = try await createNewWaypoint(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", verified: true)
        try await waypoint.detail.$language.load(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search waypoint should return the text query field is empty")
            .get(waypointsPath.appending("search/?text=bes&per=\(waypointCount)"))
            .expect(.badRequest)
            .test()
    }

}
