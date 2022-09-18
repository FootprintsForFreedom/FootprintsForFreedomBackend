//
//  TagApiDeleteTests.swift
//  
//
//  Created by niklhut on 27.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiDeleteTests: AppTestCase, TagTest {
    func testSuccessfulDeleteUnverifiedTagAsModerator() async throws {
        // Get original tag count
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        let (tagRepository, _) = try await createNewTag()
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New tag count should be one less than original tag count
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newTagCount, tagCount)
    }
    
    func testSuccessfulDeleteVerifiedTagAsModerator() async throws {
        // Get original tag count
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        let (tagRepository, _) = try await createNewTag(verifiedAt: Date())
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New tag count should be one less than original tag count
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newTagCount, tagCount)
    }
    
    func testDeleteTagRepositoryDeletesDetails() async throws {
        // Get original tag count
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let detailCount = try await TagDetailModel.query(on: app.db).count()
        
        let (tagRepository, _) = try await createNewTag(verifiedAt: Date())
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New tag count should be one less than original tag count
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newDetailCount = try await TagDetailModel.query(on: app.db).count()
        XCTAssertEqual(newTagCount, tagCount)
        XCTAssertEqual(newDetailCount, detailCount)
    }
    
    func testDeleteUnverifiedTagAsCreatorFails() async throws {
        let user = try await getUser(role: .user)
        let userToken = try user.generateToken()
        try await userToken.create(on: app.db)
        let (tagRepository, _) = try await createNewTag(verifiedAt: Date())
        
        try app
            .describe("A user should not be able to delete a tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(userToken.value)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteUnverifiedTagAsUserFails() async throws {
        let (tagRepository, _) = try await createNewTag(verifiedAt: Date())
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("A user should not be able to delete a tag")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteTagWithoutTokenFails() async throws {
        let (tagRepository, _) = try await createNewTag(verifiedAt: Date())
        
        try app
            .describe("Delete tag without token fails")
            .delete(tagPath.appending(tagRepository.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingTagFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Delete nonexistand tag fails")
            .delete(tagPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
}

extension TagApiDeleteTests: WaypointTest {
    func testDeleteWaypointDeletesWaypointTagPivot() async throws {
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let waypointTagPivotCount = try await WaypointTagModel.query(on: app.db).count()
        
        let tag = try await createNewTag()
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, on: app.db)
        
        try await waypoint.repository.delete(force: true, on: app.db)
        
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let newWaypointTagPivotCount = try await WaypointTagModel.query(on: app.db).count()
        
        XCTAssertEqual(tagCount, newTagCount - 1)
        XCTAssertEqual(waypointCount, newWaypointCount)
        XCTAssertEqual(waypointTagPivotCount, newWaypointTagPivotCount)
    }
    
    func testDeleteTagDeletesWaypointTagPivot() async throws {
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let waypointTagPivotCount = try await WaypointTagModel.query(on: app.db).count()
        
        let tag = try await createNewTag()
        let waypoint = try await createNewWaypoint()
        try await waypoint.repository.$tags.attach(tag.repository, on: app.db)
        
        try await tag.repository.delete(force: true, on: app.db)
        
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let newWaypointTagPivotCount = try await WaypointTagModel.query(on: app.db).count()
        
        XCTAssertEqual(tagCount, newTagCount)
        XCTAssertEqual(waypointCount, newWaypointCount - 1)
        XCTAssertEqual(waypointTagPivotCount, newWaypointTagPivotCount)
    }
}

extension TagApiDeleteTests: MediaTest {
    func testDeleteMediaDeletesMediaTagPivot() async throws {
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        let mediaTagPivotCount = try await MediaTagModel.query(on: app.db).count()
        
        let tag = try await createNewTag()
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, on: app.db)
        
        try await media.repository.delete(force: true, on: app.db)
        
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newMediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        let newMediaTagPivotCount = try await MediaTagModel.query(on: app.db).count()
        
        XCTAssertEqual(tagCount, newTagCount - 1)
        XCTAssertEqual(mediaCount, newMediaCount)
        XCTAssertEqual(mediaTagPivotCount, newMediaTagPivotCount)
    }
    
    func testDeleteTagDeletesMediaTagPivot() async throws {
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        let mediaTagPivotCount = try await MediaTagModel.query(on: app.db).count()
        
        let tag = try await createNewTag()
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, on: app.db)
        
        try await tag.repository.delete(force: true, on: app.db)
        
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newMediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        let newMediaTagPivotCount = try await MediaTagModel.query(on: app.db).count()
        
        XCTAssertEqual(tagCount, newTagCount)
        XCTAssertEqual(mediaCount, newMediaCount - 1)
        XCTAssertEqual(mediaTagPivotCount, newMediaTagPivotCount)
    }
}

extension TagApiDeleteTests {
    func testDeleteTagDeletesReports() async throws {
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        let reportCount = try await TagReportModel.query(on: app.db).count()
        
        let tag = try await createNewTag()
        let title = "I don't like this \(UUID())"
        let report = try await TagReportModel(
            verifiedAt: nil,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: tag.detail.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        try await tag.repository.delete(force: true, on: app.db)
        
        let newTagCount = try await TagRepositoryModel.query(on: app.db).count()
        let newReportCount = try await TagReportModel.query(on: app.db).count()
        
        XCTAssertEqual(tagCount, newTagCount)
        XCTAssertEqual(reportCount, newReportCount)
    }
}
