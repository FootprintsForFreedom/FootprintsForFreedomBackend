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

extension Model {
    static func findWithDeleted(
        _ id: Self.IDValue?,
        on database: Database
    ) async throws -> Self? {
        guard let id else { return nil }
        return try await Self.query(on: database).withDeleted().filter(\._$id == id).first()
    }
}

final class CleanupSoftDeletedModelsJobTests: AppTestCase, TagTest, WaypointTest, MediaTest, StaticContentTest, RedirectTest {
    func testSuccessfulCleanupSoftDeletedModelsJobDeletesModelsOlderThanSpecifiedInEnvironment() async throws {
        let tag = try await createNewTag()
        let createdTagReport = try await createNewTagReport(tag: tag)
        let media = try await createNewMedia()
        let createdMediaReport = try await createNewMediaReport(media: media)
        let waypoint = try await createNewWaypoint()
        let createdWaypointReport = try await createNewWaypointReport(waypoint: waypoint)
        let staticContent = try await createNewStaticContent()
        let redirect = try await createNewRedirect()
        
        try await tag.repository.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await tag.detail.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await createdTagReport.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await media.repository.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await media.detail.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await media.file.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await createdMediaReport.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await waypoint.repository.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await waypoint.detail.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await waypoint.location.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await createdWaypointReport.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await staticContent.repository.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await staticContent.detail.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        try await redirect.set(\.deletedAt, furtherBackThan: Environment.softDeletedLifetime, on: app.db)
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupSoftDeletedModelsJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.findWithDeleted(tag.repository.requireID(), on: app.db)
        XCTAssertNil(tagRepository)
        let tagDetail = try await TagDetailModel.findWithDeleted(tag.detail.requireID(), on: app.db)
        XCTAssertNil(tagDetail)
        let tagReport = try await TagReportModel.findWithDeleted(createdTagReport.requireID(), on: app.db)
        XCTAssertNil(tagReport)
        let mediaRepository = try await MediaRepositoryModel.findWithDeleted(media.repository.requireID(), on: app.db)
        XCTAssertNil(mediaRepository)
        let mediaDetail = try await MediaDetailModel.findWithDeleted(media.detail.requireID(), on: app.db)
        XCTAssertNil(mediaDetail)
        let mediaFile = try await MediaFileModel.findWithDeleted(media.file.requireID(), on: app.db)
        XCTAssertNil(mediaFile)
        let mediaReport = try await MediaReportModel.findWithDeleted(createdMediaReport.requireID(), on: app.db)
        XCTAssertNil(mediaReport)
        let waypointRepository = try await WaypointRepositoryModel.findWithDeleted(waypoint.repository.requireID(), on: app.db)
        XCTAssertNil(waypointRepository)
        let waypointDetail = try await WaypointDetailModel.findWithDeleted(waypoint.detail.requireID(), on: app.db)
        XCTAssertNil(waypointDetail)
        let waypointLocation = try await WaypointLocationModel.findWithDeleted(waypoint.location.requireID(), on: app.db)
        XCTAssertNil(waypointLocation)
        let waypointReport = try await WaypointReportModel.findWithDeleted(createdWaypointReport.requireID(), on: app.db)
        XCTAssertNil(waypointReport)
        let staticContentRepository = try await StaticContentRepositoryModel.findWithDeleted(staticContent.repository.requireID(), on: app.db)
        XCTAssertNil(staticContentRepository)
        let staticContentDetail = try await StaticContentDetailModel.findWithDeleted(staticContent.detail.requireID(), on: app.db)
        XCTAssertNil(staticContentDetail)
        let redirectResponse = try await RedirectModel.findWithDeleted(redirect.requireID(), on: app.db)
        XCTAssertNil(redirectResponse)
    }
    
    func testSuccessfulCleanupSoftDeletedModelsJobDoesNotDeleteNewerModelsThanSpecifiedInEnvironment() async throws {
        let tag = try await createNewTag()
        let createdTagReport = try await createNewTagReport(tag: tag)
        let media = try await createNewMedia()
        let createdMediaReport = try await createNewMediaReport(media: media)
        let waypoint = try await createNewWaypoint()
        let createdWaypointReport = try await createNewWaypointReport(waypoint: waypoint)
        let staticContent = try await createNewStaticContent()
        let redirect = try await createNewRedirect()
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupSoftDeletedModelsJob().run(context: context)
        
        let tagRepository = try await TagRepositoryModel.findWithDeleted(tag.repository.requireID(), on: app.db)
        XCTAssertNotNil(tagRepository)
        let tagDetail = try await TagDetailModel.findWithDeleted(tag.detail.requireID(), on: app.db)
        XCTAssertNotNil(tagDetail)
        let tagReport = try await TagReportModel.findWithDeleted(createdTagReport.requireID(), on: app.db)
        XCTAssertNotNil(tagReport)
        let mediaRepository = try await MediaRepositoryModel.findWithDeleted(media.repository.requireID(), on: app.db)
        XCTAssertNotNil(mediaRepository)
        let mediaDetail = try await MediaDetailModel.findWithDeleted(media.detail.requireID(), on: app.db)
        XCTAssertNotNil(mediaDetail)
        let mediaFile = try await MediaFileModel.findWithDeleted(media.file.requireID(), on: app.db)
        XCTAssertNotNil(mediaFile)
        let mediaReport = try await MediaReportModel.findWithDeleted(createdMediaReport.requireID(), on: app.db)
        XCTAssertNotNil(mediaReport)
        let waypointRepository = try await WaypointRepositoryModel.findWithDeleted(waypoint.repository.requireID(), on: app.db)
        XCTAssertNotNil(waypointRepository)
        let waypointDetail = try await WaypointDetailModel.findWithDeleted(waypoint.detail.requireID(), on: app.db)
        XCTAssertNotNil(waypointDetail)
        let waypointLocation = try await WaypointLocationModel.findWithDeleted(waypoint.location.requireID(), on: app.db)
        XCTAssertNotNil(waypointLocation)
        let waypointReport = try await WaypointReportModel.findWithDeleted(createdWaypointReport.requireID(), on: app.db)
        XCTAssertNotNil(waypointReport)
        let staticContentRepository = try await StaticContentRepositoryModel.findWithDeleted(staticContent.repository.requireID(), on: app.db)
        XCTAssertNotNil(staticContentRepository)
        let staticContentDetail = try await StaticContentDetailModel.findWithDeleted(staticContent.detail.requireID(), on: app.db)
        XCTAssertNotNil(staticContentDetail)
        let redirectResponse = try await RedirectModel.findWithDeleted(redirect.requireID(), on: app.db)
        XCTAssertNotNil(redirectResponse)
    }
}
