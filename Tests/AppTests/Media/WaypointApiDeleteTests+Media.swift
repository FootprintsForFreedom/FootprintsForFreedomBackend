//
//  WaypointApiDeleteTests+Media.swift
//  
//
//  Created by niklhut on 16.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension WaypointApiDeleteTests: MediaTest {
    func testDeleteWaypointDeletesAssociatedMedia() async throws {
        // Get original waypoint count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let waypointModelCount = try await WaypointDetailModel.query(on: app.db).count()
        let locationCount = try await WaypointLocationModel.query(on: app.db).count()
        let mediaRespositoryCount = try await MediaRepositoryModel.query(on: app.db).count()
        let mediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let mediaFileCount = try await MediaFileModel.query(on: app.db).count()
        
        let (waypointRepository, _, _) = try await createNewWaypoint()
        let moderatorToken = try await getToken(for: .moderator)
        let _ = try await createNewMedia(waypointId: waypointRepository.requireID())
        
        try app
            .describe("A moderator should be able to delete a waypoint and all connected media should be deleted as well")
            .delete(waypointsPath.appending(waypointRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let newWaypointModelCount = try await WaypointDetailModel.query(on: app.db).count()
        let newLocationCount = try await WaypointLocationModel.query(on: app.db).count()
        let newMediaRespositoryCount = try await MediaRepositoryModel.query(on: app.db).count()
        let newMediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let newMediaFileCount = try await MediaFileModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
        XCTAssertEqual(newWaypointModelCount, waypointModelCount)
        XCTAssertEqual(newLocationCount, locationCount)
        XCTAssertEqual(newMediaRespositoryCount, mediaRespositoryCount)
        XCTAssertEqual(newMediaDetailCount, mediaDetailCount)
        XCTAssertEqual(newMediaFileCount, mediaFileCount)
    }
}
