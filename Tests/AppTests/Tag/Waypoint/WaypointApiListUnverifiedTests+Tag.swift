//
//  WaypointApiListUnverifiedTests+Tag.swift
//  
//
//  Created by niklhut on 31.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension WaypointApiListUnverifiedTests: TagTest {
    func testSuccessfulListRepositoriesWithUnverifiedModelsReturnsModelsWithUnverifiedTags() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let waypoint = try await createNewWaypoint(verified: true)
        
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .count()
        
        try app
            .describe("List repositories with unverified models should also return repositories with unverified tag connections")
            .get(waypointsPath.appending("unverified/?per=\(waypointCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
    
    func testSuccessfulListRepositoriesWithUnverifiedModelsReturnsModelsWithRequestDeletedTags() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let waypoint = try await createNewWaypoint(verified: true)
        
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        let tagPivot = try await waypoint.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == waypoint.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .deleteRequested
        try await tagPivot.save(on: app.db)
        
        let waypointCount = try await WaypointRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .count()
        
        try app
            .describe("List repositories with unverified models should also return repositories with a tag that was requested to be deleted")
            .get(waypointsPath.appending("unverified/?per=\(waypointCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()

    }
}
