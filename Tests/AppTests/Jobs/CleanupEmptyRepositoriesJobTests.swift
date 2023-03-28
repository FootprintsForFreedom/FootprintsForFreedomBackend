//
//  CleanupEmptyRepositoriesJobTests.swift
//  
//
//  Created by niklhut on 12.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Queues
import Spec

final class CleanupEmptyRepositoriesJobTests: AppTestCase, TagTest, WaypointTest, MediaTest {
    func testSuccessfulCleanupEmptyRepositoriesJobDeletesEmptyRepositories() async throws {
        let tag = try await createNewTag()
        try await tag.detail.delete(force: true, on: app.db)
        let media = try await createNewMedia()
        try await media.detail.delete(force: true, on: app.db)
        let waypoint = try await createNewWaypoint()
        try await waypoint.detail.delete(force: true, on: app.db)
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupEmptyRepositoriesJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.find(tag.repository.requireID(), on: app.db)
        let mediaRepository = try await MediaRepositoryModel.find(media.repository.requireID(), on: app.db)
        let waypointRepository = try await WaypointRepositoryModel.find(waypoint.repository.requireID(), on: app.db)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNil(tagRepository)
        XCTAssertNil(mediaRepository)
        XCTAssertNil(waypointRepository)
        XCTAssertNil(mediaFile)
    }
    
    func testSuccessfulCleanupEmptyRepositoriesJobDoesNotDeleteRepositoriesWithSoftDeletedChildren() async throws {
        let tag = try await createNewTag()
        try await tag.detail.delete(on: app.db)
        let media = try await createNewMedia()
        try await media.detail.delete(on: app.db)
        let waypoint = try await createNewWaypoint()
        try await waypoint.detail.delete(on: app.db)
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupEmptyRepositoriesJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.find(tag.repository.requireID(), on: app.db)
        let mediaRepository = try await MediaRepositoryModel.find(media.repository.requireID(), on: app.db)
        let waypointRepository = try await WaypointRepositoryModel.find(waypoint.repository.requireID(), on: app.db)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNotNil(tagRepository)
        XCTAssertNotNil(mediaRepository)
        XCTAssertNotNil(waypointRepository)
        XCTAssertNotNil(mediaFile)
    }
    
    func testSuccessfulCleanupEmptyRepositoriesJobDoesNotDeleteRepositoriesWithChildren() async throws {
        let tag = try await createNewTag()
        let media = try await createNewMedia()
        let waypoint = try await createNewWaypoint()
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupEmptyRepositoriesJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.find(tag.repository.requireID(), on: app.db)
        let mediaRepository = try await MediaRepositoryModel.find(media.repository.requireID(), on: app.db)
        let waypointRepository = try await WaypointRepositoryModel.find(waypoint.repository.requireID(), on: app.db)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNotNil(tagRepository)
        XCTAssertNotNil(mediaRepository)
        XCTAssertNotNil(waypointRepository)
        XCTAssertNotNil(mediaFile)
    }
}
