//
//  CleanupOldVerifiedModelsJobTests.swift
//  
//
//  Created by niklhut on 28.08.22.
//

@testable import App
import XCTVapor
import Fluent
import Queues
import Spec

final class CleanupOldVerifiedModelsJobTests: AppTestCase, TagTest, WaypointTest, MediaTest, StaticContentTest {
    func testSuccessfulCleanupOldVerifiedModelsJobDeletesModelsOlderThanSpecifiedInEnvironment() async throws {
        let tag = try await createNewTag(verified: true)
        try await tag.detail.updateWith(verifiedAt: Date(), on: app.db)
        let createdTagReport = try await createNewTagReport(tag: tag, verifiedAt: Date())
        let media = try await createNewMedia(verifiedAt: Date())
        try await media.detail.updateWith(verifiedAt: Date(), on: app.db)
        let createdMediaReport = try await createNewMediaReport(media: media, verifiedAt: Date())
        let waypoint = try await createNewWaypoint(verified: true)
        try await waypoint.detail.updateWith(verifiedAt: Date(), on: app.db)
        try await waypoint.location.updateWith(verifiedAt: Date(), on: app.db)
        let createdWaypointReport = try await createNewWaypointReport(waypoint: waypoint, verifiedAt: Date())
        let staticContent = try await createNewStaticContent()
        try await staticContent.detail.updateWith(on: app.db)
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupOldVerifiedModelsJob().run(context: context)
        
        let tagDetail = try await TagDetailModel.find(tag.detail.requireID(), on: app.db)
        XCTAssertNil(tagDetail)
        let tagReport = try await TagReportModel.find(createdTagReport.requireID(), on: app.db)
        XCTAssertNil(tagReport)
        let mediaDetail = try await MediaDetailModel.find(media.detail.requireID(), on: app.db)
        XCTAssertNil(mediaDetail)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNotNil(mediaFile)
        let mediaReport = try await MediaReportModel.find(createdMediaReport.requireID(), on: app.db)
        XCTAssertNil(mediaReport)
        let waypointDetail = try await WaypointDetailModel.find(waypoint.detail.requireID(), on: app.db)
        XCTAssertNil(waypointDetail)
        let waypointLocation = try await WaypointLocationModel.find(waypoint.location.requireID(), on: app.db)
        XCTAssertNil(waypointLocation)
        let waypointReport = try await WaypointReportModel.find(createdWaypointReport.requireID(), on: app.db)
        XCTAssertNil(waypointReport)
        let staticContentDetail = try await StaticContentDetailModel.find(staticContent.detail.requireID(), on: app.db)
        XCTAssertNil(staticContentDetail)
    }
    
    func testSuccessfulCleanupOldVerifiedModelsJobDeletesMediaFilesIfItIsNotUsedAnymore() async throws {
        let media = try await createNewMedia(verifiedAt: Date())
        let newMediaFile = try await MediaFileModel.createWith(
            mediaDirectory: UUID().uuidString,
            group: .allCases.randomElement()!,
            userId: media.detail.$user.id!,
            on: app.db
        )
        try await media.detail.updateWith(verifiedAt: Date(), fileId: newMediaFile.requireID(), on: app.db)
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupOldVerifiedModelsJob().run(context: context)
        
        let mediaDetail = try await MediaDetailModel.find(media.detail.requireID(), on: app.db)
        XCTAssertNil(mediaDetail)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNil(mediaFile)
    }
    
    func testSuccessfulCleanupOldVerifiedModelsJobDoesNotDeleteModelsOlderThanSpecifiedInEnvironmentIfTheyAreTheNewestVerifiedOnes() async throws {
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia(verifiedAt: Date())
        let waypoint = try await createNewWaypoint(verified: true)
        let staticContent = try await createNewStaticContent()
        
        let context = QueueContext(
                    queueName: .init(string: "test"),
                    configuration: .init(),
                    application: app,
                    logger: app.logger,
                    on: app.eventLoopGroup.next()
                )
        
        try await CleanupOldVerifiedModelsJob().run(context: context)
        
        let tagDetail = try await TagDetailModel.find(tag.detail.requireID(), on: app.db)
        XCTAssertNotNil(tagDetail)
        let mediaDetail = try await MediaDetailModel.find(media.detail.requireID(), on: app.db)
        XCTAssertNotNil(mediaDetail)
        let mediaFile = try await MediaFileModel.find(media.file.requireID(), on: app.db)
        XCTAssertNotNil(mediaFile)
        let waypointDetail = try await WaypointDetailModel.find(waypoint.detail.requireID(), on: app.db)
        XCTAssertNotNil(waypointDetail)
        let waypointLocation = try await WaypointLocationModel.find(waypoint.location.requireID(), on: app.db)
        XCTAssertNotNil(waypointLocation)
        let staticContentDetail = try await StaticContentDetailModel.find(staticContent.detail.requireID(), on: app.db)
        XCTAssertNotNil(staticContentDetail)
    }
    
    // Cannot test this when oldVerifiedLifetime is set to 0 in Environment to test the successful deletion.
    // func testSuccessfulCleanupOldVerifiedModelsJobDoesNotDeleteModelsNewerThanSpecifiedInEnvironment() async throws {
    // }
}
