//
//  MediaApiDeleteTests.swift
//  
//
//  Created by niklhut on 14.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiDeleteTests: AppTestCase, MediaTest {
    func testSuccessfulDeleteUnverifiedMediaAsModerator() async throws {
        // Get original media count
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        let (mediaRepository, _, _) = try await createNewMedia()
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete an unverified media")
            .delete(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newMediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newMediaCount, mediaCount)
    }
    
    func testSuccessfulDeleteVerifiedMediaAsModerator() async throws {
        // Get original media count
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        let (mediaRepository, _, _) = try await createNewMedia(verifiedAt: Date())
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete a verified media")
            .delete(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newMediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newMediaCount, mediaCount)
    }
    
    func testDeleteMediaRepositoryDeletesDetailsAndFiles() async throws {
        // Get original media count
        let mediaRepositoryCount = try await MediaRepositoryModel.query(on: app.db).count()
        let mediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let mediaFileCount = try await MediaFileModel.query(on: app.db).count()
        
        let (mediaRepository, _, _) = try await createNewMedia(verifiedAt: Date())
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("A moderator should be able to delete a verified media")
            .delete(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New media count should be original count
        let newMediaRepositoryCount = try await MediaRepositoryModel.query(on: app.db).count()
        let newMediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let newMediaFileCount = try await MediaFileModel.query(on: app.db).count()
        XCTAssertEqual(newMediaRepositoryCount, mediaRepositoryCount)
        XCTAssertEqual(newMediaDetailCount, mediaDetailCount)
        XCTAssertEqual(newMediaFileCount, mediaFileCount)
    }
    
    func testDeleteUnverifiedMediaAsCreatorFails() async throws {
        let user = try await getUser(role: .user)
        let userToken = try user.generateToken()
        try await userToken.create(on: app.db)
        let (mediaRepository, _, _) = try await createNewMedia(userId: user.requireID())
        
        try app
            .describe("A user should not be able to delete a waypoint")
            .delete(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(userToken.value)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteUnverifiedMediaAsUserFails() async throws {
        let (mediaRepository, _, _) = try await createNewMedia()
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("A user should not be able to delete a waypoint")
            .delete(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteMediaWithoutTokenFails() async throws {
        let (mediaRepository, _, _) = try await createNewMedia()
        
        try app
            .describe("Delete media without token fails")
            .delete(mediaPath.appending(mediaRepository.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingMediaFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        try app
            .describe("Delete nonexistent media fails")
            .delete(mediaPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
}

extension MediaApiDeleteTests {
    func testDeleteMediaDeletesReports() async throws {
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        let reportCount = try await MediaReportModel.query(on: app.db).count()
        
        let media = try await createNewMedia()
        let title = "I don't like this \(UUID())"
        let report = try await MediaReportModel(
            verifiedAt: nil,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: media.detail.requireID(),
            repositoryId: media.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        try await media.repository.delete(force: true, on: app.db)
        
        let newMediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        let newReportCount = try await MediaReportModel.query(on: app.db).count()
        
        XCTAssertEqual(mediaCount, newMediaCount)
        XCTAssertEqual(reportCount, newReportCount)
    }
}
