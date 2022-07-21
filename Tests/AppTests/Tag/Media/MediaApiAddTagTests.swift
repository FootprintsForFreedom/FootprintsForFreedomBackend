//
//  MediaApiAddTagTests.swift
//  
//
//  Created by niklhut on 21.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiAddTagTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulAddTagToMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(status: .verified)
        let media = try await createNewMedia()
        try await media.detail.$language.load(on: app.db)
        
        try app
            .describe("Add tag to media should return ok and the media")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, media.repository.id)
                XCTAssertEqual(content.title, media.detail.title)
                XCTAssertEqual(content.detailText, media.detail.detailText)
                XCTAssertEqual(content.languageCode, media.detail.language.languageCode)
                XCTAssertEqual(content.group, media.file.group)
                XCTAssertEqual(content.filePath, media.file.mediaDirectory)
                XCTAssert(!content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNil(content.status)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testAddTagToMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let tag = try await createNewTag(status: .verified)
        let media = try await createNewMedia()
        
        try app
            .describe("Add tag to media as unverified user should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testAddTagToMediasWithoutTokenFails() async throws {
        let tag = try await createNewTag(status: .verified)
        let media = try await createNewMedia()
        
        try app
            .describe("Add tag to media requires verified tag")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testAddTagToMediasNeedsValidMediaId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(status: .verified)
        
        try app
            .describe("Add tag to media requires valid (but not necessarily verified) media id")
            .post(mediaPath.appending("\(UUID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.notFound)
            .test()
    }
    
    func testAddTagToMediasNeedsVerifiedTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let media = try await createNewMedia()
        
        try app
            .describe("Add tag to media requires verified tag")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
