//
//  MediaApiVerifyTagTests.swift
//  
//
//  Created by niklhut on 21.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiVerifyTagTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulVerifyTagOnMedia() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag on media should return ok and the media with the tag")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, media.repository.id)
                XCTAssertEqual(content.title, media.detail.title)
                XCTAssertEqual(content.detailText, media.detail.detailText)
                XCTAssertEqual(content.languageCode, media.detail.language.languageCode)
                XCTAssertEqual(content.fileType, media.file.fileType)
                XCTAssertEqual(content.filePath, media.file.relativeMediaFilePath)
                XCTAssert(content.tags.contains { $0.id == tag.repository.id })
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testVerifyTagOnMediaAsUserFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on media as user should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyTagOnMediaWithoutTokenFails() async throws {
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on media without token should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyTagOnMediaNeedsValidMediaId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        
        try app
            .describe("Verify tag on media required valid media id")
            .post(mediaPath.appending("\(UUID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testVerifyTagOnMediaNeedsValidTagId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        
        try app
            .describe("Verify tag on media requires valid tag id")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(UUID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testVerifyTagOnMediaNeedsConnectedTagAndMedia() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        
        try app
            .describe("Verify tag on media requires connected tag and media")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testVerifyTagOnMediaWithAlreadyVerifiedTagFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        let tagPivot = try await media.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == media.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify tag on media with already verified tag should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()

    }
}
