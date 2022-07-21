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
    
    struct TestFile {
        let mimeType: String
        let filename: String
        let fileExtension: String
    }
    
    func testSuccessfulCreateMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent()
        
        // Get original media count
        let mediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let mediaFileCount = try await MediaFileModel.query(on: app.db).count()
        var newRepositoryId: UUID!
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        
        let testFiles: [TestFile] = [
            .init(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png"),
            .init(mimeType: "image/jpeg", filename: "Logo_groß", fileExtension: "jpg"),
            .init(mimeType: "video/quicktime", filename: "1280", fileExtension: "mov"),
            .init(mimeType: "video/mp4", filename: "640", fileExtension: "mp4"),
            .init(mimeType: "audio/mpeg", filename: "samplemp3", fileExtension: "mp3"),
            .init(mimeType: "audio/vnd.wave", filename: "Wav_868kb", fileExtension: "wav"),
            .init(mimeType: "application/pdf", filename: "SamplePdf", fileExtension: "pdf")
        ]
        
        // this already tests for duplicate titles since the title is the same for each different file
        for file in testFiles {
            let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
            try app
                .describe("Create media should return ok")
                .post(mediaPath.appending("?\(query)"))
                .buffer(ByteBuffer(data: fileData))
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
                    XCTAssertNil(content.status)
                }
                .test()
        }
        
        // New media count should be one more than original media count
        let newMediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let newMediaFileCount = try await MediaFileModel.query(on: app.db).count()
        XCTAssertEqual(newMediaDetailCount, mediaDetailCount + testFiles.count)
        XCTAssertEqual(newMediaFileCount, mediaFileCount + testFiles.count)
        
        // check the new model is unverified
        if let newRepositoryId = newRepositoryId {
            let media = try await MediaRepositoryModel
                .find(newRepositoryId, on: app.db)!
                .$details
                .query(on: app.db)
                .sort(\.$createdAt, .descending)
                .first()!
            XCTAssertEqual(media.status, .pending)
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
        
        let testFiles: [TestFile] = [
            .init(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png"),
            .init(mimeType: "image/jpeg", filename: "Logo_groß", fileExtension: "jpg"),
            .init(mimeType: "video/quicktime", filename: "1280", fileExtension: "mov"),
            .init(mimeType: "video/mp4", filename: "640", fileExtension: "mp4"),
            .init(mimeType: "audio/mpeg", filename: "samplemp3", fileExtension: "mp3"),
            .init(mimeType: "audio/vnd.wave", filename: "Wav_868kb", fileExtension: "wav"),
            .init(mimeType: "application/pdf", filename: "SamplePdf", fileExtension: "pdf")
        ]
        
        for file in testFiles {
            let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
            try app
                .describe("Create media as moderator should return ok")
                .post(mediaPath.appending("?\(query)"))
                .buffer(ByteBuffer(data: fileData))
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
                    XCTAssertNotNil(content.status)
                }
                .test()
        }
        
        // New media count should be one more than original media count
        let newMediaDetailCount = try await MediaDetailModel.query(on: app.db).count()
        let newMediaFileCount = try await MediaFileModel.query(on: app.db).count()
        XCTAssertEqual(newMediaDetailCount, mediaDetailCount + testFiles.count)
        XCTAssertEqual(newMediaFileCount, mediaFileCount + testFiles.count)
        
        // check the new model is unverified
        if let newRepositoryId = newRepositoryId {
            let media = try await MediaRepositoryModel
                .find(newRepositoryId, on: app.db)!
                .$details
                .query(on: app.db)
                .sort(\.$createdAt, .descending)
                .first()!
            XCTAssertEqual(media.status, .pending)
        } else {
            XCTFail("Could not find repository on db")
        }
    }
    
    func testCreateMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let newMedia = try await getMediaCreateContent()
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media as unverified user should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateMediaWithoutTokenFails() async throws {
        let newMedia = try await getMediaCreateContent()
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media without token should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateMediaNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(title: "")
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media with empty title should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidDetailText() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(detailText: "")
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media with empty detailText should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(source: "")
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media with empty source should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia1 = try await getMediaCreateContent(languageCode: "")
        let newMedia2 = try await getMediaCreateContent(languageCode: "hi")
        
        let query1 = try URLEncodedFormEncoder().encode(newMedia1)
        let query2 = try URLEncodedFormEncoder().encode(newMedia2)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media with empty language should fail")
            .post(mediaPath.appending("?\(query1)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Create media with empty language should fail")
            .post(mediaPath.appending("?\(query2)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidWaypointId() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent(waypointId: UUID())
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media with empty source should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", file.mimeType)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateMediaNeedsValidContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newMedia = try await getMediaCreateContent()
        
        let query = try URLEncodedFormEncoder().encode(newMedia)
        let file = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: file.filename, withExtension: file.fileExtension)
            
        try app
            .describe("Create media with empty source should fail")
            .post(mediaPath.appending("?\(query)"))
            .buffer(ByteBuffer(data: fileData))
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
