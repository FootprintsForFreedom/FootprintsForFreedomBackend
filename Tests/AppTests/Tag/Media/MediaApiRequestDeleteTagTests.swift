//
//  MediaApiRequestDeleteTagTests.swift
//  
//
//  Created by niklhut on 21.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiRequestDeleteTagTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulRequestDeleteTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)
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
            .describe("Request delete tag on media should succeed and return the media")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
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
    
    func testRequestDeleteTagAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Request delete tag on media as unverified user should fail")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testRequestDeleteTagWithoutTokenFails() async throws {
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Request delete tag on media without token should fail")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testRequestDeleteTagOnlyWorksWithVerifiedTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        try await media.repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        let tagPivot = try await media.repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == media.repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Request delete tag should only work with verified tag")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testRequestDeleteTagNeedsValidMediaId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)
        
        try app
            .describe("Request delete tag on media required valid media id")
            .delete(mediaPath.appending("\(UUID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.notFound)
            .test()
    }
    
    func testRequestDeleteTagNeedsValidTagId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let media = try await createNewMedia()
        
        try app
            .describe("Request delete tag on media requires valid tag id")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/\(UUID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testRequestDeleteTagNeedsConnectedTagAndMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag(verified: true)
        let media = try await createNewMedia()
        
        try app
            .describe("Request delete tag on media requires connected tag and media")
            .delete(mediaPath.appending("\(media.repository.requireID())/tags/\(tag.repository.requireID())"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
