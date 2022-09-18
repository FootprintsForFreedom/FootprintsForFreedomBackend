//
//  WaypointApiListUnverifiedTagsTests.swift
//  
//
//  Created by niklhut on 31.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiListUnverifiedTagsTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulListUnverifiedTagsListsUnverifiedTag() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("List unverified tags should list an unverified tag connection")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/tags/unverified"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Repository.ListUnverifiedRelation].self) { content in
                XCTAssert(content.contains { $0.tagId == tag.repository.id!})
                if let responseTag = content.first(where: { $0.tagId == tag.repository.id! }) {
                    XCTAssertEqual(responseTag.title, tag.detail.title)
                    XCTAssertEqual(responseTag.status, .pending)
                }
            }
            .test()
    }
    
    func testSuccessfulListUnverifiedTagsListsRequestDeletedTag() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        let tagPivot = try await waypoint.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == waypoint.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .deleteRequested
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("List unverified tags should list an request deleted tag connection")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/tags/unverified"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Repository.ListUnverifiedRelation].self) { content in
                XCTAssert(content.contains { $0.tagId == tag.repository.id!})
                if let responseTag = content.first(where: { $0.tagId == tag.repository.id! }) {
                    XCTAssertEqual(responseTag.title, tag.detail.title)
                    XCTAssertEqual(responseTag.status, .deleteRequested)
                }
            }
            .test()
    }
    
    func testSuccessfulListUnverifiedTagsDoesNotListVerifiedTag() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        let tagPivot = try await waypoint.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == waypoint.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("List unverified tags should not list a verified tag connection")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/tags/unverified"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Repository.ListUnverifiedRelation].self) { content in
                XCTAssert(!content.contains { $0.tagId == tag.repository.id!})
            }
            .test()
    }
    
    func testListUnverifiedTagsAsUserFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("List unverified tags as user should fail")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/tags/unverified"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedTagsWithoutTokenFails() async throws {
        let tag = try await createNewTag(verifiedAt: Date())
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("List unverified tags without token should fail")
            .get(waypointsPath.appending("\(waypoint.repository.requireID())/tags/unverified"))
            .expect(.unauthorized)
            .test()
        
    }
}
