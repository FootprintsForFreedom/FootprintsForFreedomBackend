//
//  MediaApiCreateTests.swift
//  
//
//  Created by niklhut on 13.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Media.Detail.Create: Content { }
extension Data: Content { }

final class MediaApiCreateTests: AppTestCase, MediaTest {
    private func getMediaCreateContent(
        title: String = "New Media Title \(UUID())",
        detailText: String = "New Media Description",
        source: String = "New Media Source",
        languageCode: String? = nil,
        waypointId: UUID? = nil
    ) async throws -> Media.Detail.Create {
        var languageCode: String! = languageCode
        if languageCode == nil {
            languageCode = try await createLanguage().languageCode
        }
        var waypointId: UUID! = waypointId
        if waypointId == nil {
            waypointId = try await createNewWaypoint().repository.id
        }
        return .init(title: title, detailText: detailText, source: source, languageCode: languageCode, waypointId: waypointId)
    }
    
    func testSuccessfulCreateMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent()
        
        // Get original media count
        let mediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let mediaFileCount = try await MediaFileModel.query(on: app.db).count()
        var newRepositoryId: UUID!
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        
        // this already tests for duplicate titles since the title is the same for each different file
        for file in FileUtils.testFiles {
            try app
                .describe("Create media should return ok")
                .post(mediaPath.appending("?\(query)"))
                .buffer(try FileUtils.data(for: file))
                .header("Content-Type", file.mimeType)
                .bearerToken(token)
                .expect(.created)
                .expect(.json)
                .expect(Media.Detail.Detail.self) { content in
                    XCTAssertNotNil(content.id)
                    newRepositoryId = content.id
                    XCTAssertEqual(content.title, newMedia.title)
                    XCTAssertNotEqual(content.slug, newMedia.title.slugify())
                    XCTAssertContains(content.slug, newMedia.title.slugify())
                    XCTAssertEqual(content.detailText, newMedia.detailText)
                    XCTAssertEqual(content.source, newMedia.source)
                    XCTAssertEqual(content.languageCode, newMedia.languageCode)
                }
                .test()
        }
        
        // New media count should be one more than original media count
        let newMediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let newMediaFileCount = try await MediaFileModel.query(on: app.db).count()
        XCTAssertEqual(newMediaDetailCount, mediaDetailCount + FileUtils.testFiles.count)
        XCTAssertEqual(newMediaFileCount, mediaFileCount + FileUtils.testFiles.count)
        
        // check the new model is unverified
        if let newRepositoryId = newRepositoryId {
            let media = try await MediaRepositoryModel
                .find(newRepositoryId, on: app.db)!
                .$details
                .query(on: app.db)
                .sort(\.$createdAt, .descending)
                .first()!
            XCTAssertNil(media.verifiedAt)
        } else {
            XCTFail("Could not find repository on db")
        }
    }
    
    func testSuccessfulCreateMediaAsModerator() async throws {
        let token = try await getToken(for: .moderator, verified: true)
        let newMedia = try await getMediaCreateContent()
        
        // Get original media count
        let mediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let mediaFileCount = try await MediaFileModel.query(on: app.db).count()
        var newRepositoryId: UUID!
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        
        for file in FileUtils.testFiles {
            try app
                .describe("Create media as moderator should return ok")
                .post(mediaPath.appending("?\(query)"))
                .buffer(try FileUtils.data(for: file))
                .header("Content-Type", file.mimeType)
                .bearerToken(token)
                .expect(.created)
                .expect(.json)
                .expect(Media.Detail.Detail.self) { content in
                    XCTAssertNotNil(content.id)
                    newRepositoryId = content.id
                    XCTAssertEqual(content.title, newMedia.title)
                    XCTAssertNotEqual(content.slug, newMedia.title.slugify())
                    XCTAssertContains(content.slug, newMedia.title.slugify())
                    XCTAssertEqual(content.detailText, newMedia.detailText)
                    XCTAssertEqual(content.source, newMedia.source)
                    XCTAssertEqual(content.languageCode, newMedia.languageCode)
                }
                .test()
        }
        
        // New media count should be one more than original media count
        let newMediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let newMediaFileCount = try await MediaFileModel.query(on: app.db).count()
        XCTAssertEqual(newMediaDetailCount, mediaDetailCount + FileUtils.testFiles.count)
        XCTAssertEqual(newMediaFileCount, mediaFileCount + FileUtils.testFiles.count)
        
        // check the new model is unverified
        if let newRepositoryId = newRepositoryId {
            let media = try await MediaRepositoryModel
                .find(newRepositoryId, on: app.db)!
                .$details
                .query(on: app.db)
                .sort(\.$createdAt, .descending)
                .first()!
            XCTAssertNil(media.verifiedAt)
        } else {
            XCTFail("Could not find repository on db")
        }
    }
    
    func testCreateMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let newMedia = try await getMediaCreateContent()
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
            
        try app
            .describe("Create media as unverified user should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateMediaWithoutTokenFails() async throws {
        let newMedia = try await getMediaCreateContent()
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
            
        try app
            .describe("Create media without token should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateMediaNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(title: "")
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media with empty title should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidDetailText() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(detailText: "")
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media with empty detailText should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(source: "")
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media with empty source should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia1 = try await getMediaCreateContent(languageCode: "")
        let newMedia2 = try await getMediaCreateContent(languageCode: "zz")
        
        let query1 = try URLEncodedFormEncoder().encode(newMedia1)
        let query2 = try URLEncodedFormEncoder().encode(newMedia2)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media with empty language should fail")
            .post(mediaPath.appending("?\(query1)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Create media with empty language should fail")
            .post(mediaPath.appending("?\(query2)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaForDeactivatedLanguageFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let language = try await createLanguage(activated: false)
        let newMedia = try await getMediaCreateContent(languageCode: language.languageCode)
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media for deactivated language code should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidWaypointId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(waypointId: UUID())
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media with empty source should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent()
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = FileUtils.testImage
        
        try app
            .describe("Create media with empty source should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(try FileUtils.data(for: file))
            .header("Content-Type", "hallo/test")
            .bearerToken(token)
            .expect(.unsupportedMediaType)
            .test()
    }
    
    func testCreateMediaWithWrongPayloadFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        
        try app
            .describe("Creating a user with wrong payload fails")
            .post(mediaPath)
            .body(["wrong input": "Test Category"])
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
