//
//  TagApiGetWaypointsTests.swift
//  
//
//  Created by niklhut on 21.02.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiGetWaypointsTests: AppTestCase, WaypointTest, TagTest {
    func testSuccessfulGetWaypointsForTag() async throws {
        let tag = try await createNewTag(verified: true)
        let waypoint = try await createNewWaypoint(verified: true)
        try await waypoint.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoints with the tag")
            .post(waypointsPath.appending("\(waypoint.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, waypoint.repository.id)
                XCTAssert(content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNotNil(content.detailId)
            }
            .test()
        
        let waypointsCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get waypoints for tag should return ok and the waypoints for the tag.")
            .get(tagPath.appending("\(tag.repository.requireID())/waypoints/?per=\(waypointsCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Waypoint.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == waypoint.repository.id })
            }
            .test()
    }
}
