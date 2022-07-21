//
//  MediaApiDeleteTagTests.swift
//  
//
//  Created by niklhut on 21.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiDeleteTagTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulDeleteTagOnMedia() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        let tagPivot = try await media.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == media.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Delete tag on media should succeed and return the media without the tag")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
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
                XCTAssertNotNil(content.status)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testDeleteTagOnMediaAsUserFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(status: .verified)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Delete tag on media as user should fail")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteTagOnMediaWithoutTokenFails() async throws {
        let tag = try await createNewTag(status: .verified)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Delete tag on media wihtout token should fail")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteTagOnMediaNeedsValidMediaId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag(status: .verified)
        
        try app
            .describe("Delete tag on media required valid media id")
            .delete(mediaPath.appending("\(UUID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDeleteTagOnMediaNeedsValidTagId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        
        try app
            .describe("Delete tag on media rqeuires valid tag id")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/verify/\(UUID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
