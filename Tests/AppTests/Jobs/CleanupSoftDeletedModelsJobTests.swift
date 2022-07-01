//
//  CleanupSoftDeletedModelsJobTests.swift
//  
//
//  Created by niklhut on 13.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Queues
import Spec

extension Timestamped {
    func setDeletedAtFurtherThanSoftDeletedLifetime(_ db: Database) async throws {
        guard let softDeletedLifetime = Environment.softDeletedLifetime else {
            return
        }
        let dayInSeconds = 60 * 60 * 24
        self.deletedAt = Date().addingTimeInterval(TimeInterval(-1 * dayInSeconds * (softDeletedLifetime + 1)))
        try await self.update(on: db)
    }
}

final class CleanupSoftDeletedModelsJobTests: AppTestCase, TagTest, WaypointTest, MediaTest, StaticContentTest {
    func testSuccessfulCleanupSoftDeletedModelsJobDeletesModelsOlderThanSpecifiedInEnvironment() async throws {
        let tag = try await createNewTag()
        let createdTagReport = try await createNewTagReport(tag: tag)
        let media = try await createNewMedia()
        let createdMediaReport = try await createNewMediaReport(media: media)
        let waypoint = try await createNewWaypoint()
        let createdWaypointReport = try await createNewWaypointReport(waypoint: waypoint)
        let staticContent = try await createNewStaticContent()
        
        try await tag.repository.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await tag.detail.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await createdTagReport.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await media.repository.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await media.detail.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await media.file.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await createdMediaReport.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await waypoint.repository.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await waypoint.detail.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await waypoint.location.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await createdWaypointReport.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await staticContent.repository.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        try await staticContent.detail.setDeletedAtFurtherThanSoftDeletedLifetime(app.db)
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupSoftDeletedModelsJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.find(tag.repository.requireID(), on: app.db)
        XCTAssertNil(tagRepository)
        let tagDetail = try await TagDetailModel.find(tag.detail.requireID(), on: app.db)
        XCTAssertNil(tagDetail)
        let tagReport = try await TagReportModel.find(createdTagReport.requireID(), on: app.db)
        XCTAssertNil(tagReport)
        let mediaRepository = try await MediaRepositoryModel.find(media.repository.requireID(), on: app.db)
        XCTAssertNil(mediaRepository)
        let mediaDetail = try await MediaDetailModel.find(media.detail.requireID(), on: app.db)
        XCTAssertNil(mediaDetail)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNil(mediaFile)
        let mediaReport = try await MediaReportModel.find(createdMediaReport.requireID(), on: app.db)
        XCTAssertNil(mediaReport)
        let waypointRepository = try await WaypointRepositoryModel.find(waypoint.repository.requireID(), on: app.db)
        XCTAssertNil(waypointRepository)
        let waypointDetail = try await WaypointDetailModel.find(waypoint.detail.requireID(), on: app.db)
        XCTAssertNil(waypointDetail)
        let waypointLocation = try await WaypointLocationModel.find(waypoint.location.requireID(), on: app.db)
        XCTAssertNil(waypointLocation)
        let waypointReport = try await WaypointReportModel.find(createdWaypointReport.requireID(), on: app.db)
        XCTAssertNil(waypointReport)
        let staticContentRepository = try await StaticContentRepositoryModel.find(staticContent.repository.requireID(), on: app.db)
        XCTAssertNil(staticContentRepository)
        let staticContentDetail = try await StaticContentDetailModel.find(staticContent.detail.requireID(), on: app.db)
        XCTAssertNil(staticContentDetail)
    }
    
    func testSuccessfulCleanupSoftDeletedModelsJobDoesNotDeleteNewerModelsThanSpecifiedInEnvironment() async throws {
        let tag = try await createNewTag()
        let createdTagReport = try await createNewTagReport(tag: tag)
        let media = try await createNewMedia()
        let createdMediaReport = try await createNewMediaReport(media: media)
        let waypoint = try await createNewWaypoint()
        let createdWaypointReport = try await createNewWaypointReport(waypoint: waypoint)
        let staticContent = try await createNewStaticContent()
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupSoftDeletedModelsJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.find(tag.repository.requireID(), on: app.db)
        XCTAssertNotNil(tagRepository)
        let tagDetail = try await TagDetailModel.find(tag.detail.requireID(), on: app.db)
        XCTAssertNotNil(tagDetail)
        let tagReport = try await TagReportModel.find(createdTagReport.requireID(), on: app.db)
        XCTAssertNotNil(tagReport)
        let mediaRepository = try await MediaRepositoryModel.find(media.repository.requireID(), on: app.db)
        XCTAssertNotNil(mediaRepository)
        let mediaDetail = try await MediaDetailModel.find(media.detail.requireID(), on: app.db)
        XCTAssertNotNil(mediaDetail)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNotNil(mediaFile)
        let mediaReport = try await MediaReportModel.find(createdMediaReport.requireID(), on: app.db)
        XCTAssertNotNil(mediaReport)
        let waypointRepository = try await WaypointRepositoryModel.find(waypoint.repository.requireID(), on: app.db)
        XCTAssertNotNil(waypointRepository)
        let waypointDetail = try await WaypointDetailModel.find(waypoint.detail.requireID(), on: app.db)
        XCTAssertNotNil(waypointDetail)
        let waypointLocation = try await WaypointLocationModel.find(waypoint.location.requireID(), on: app.db)
        XCTAssertNotNil(waypointLocation)
        let waypointReport = try await WaypointReportModel.find(createdWaypointReport.requireID(), on: app.db)
        XCTAssertNotNil(waypointReport)
        let staticContentRepository = try await StaticContentRepositoryModel.find(staticContent.repository.requireID(), on: app.db)
        XCTAssertNotNil(staticContentRepository)
        let staticContentDetail = try await StaticContentDetailModel.find(staticContent.detail.requireID(), on: app.db)
        XCTAssertNotNil(staticContentDetail)
    }
}