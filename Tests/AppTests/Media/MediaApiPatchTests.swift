//
//  MediaApiPatchTests.swift
//  
//
//  Created by niklhut on 16.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Media.Media.Patch: Content { }

final class MediaApiPatchTests: AppTestCase, MediaTest {
    let mediaPath = "api/media/"
    
    private func getMediaPatchContent(
        title: String = "New Meidia Title \(UUID())",
        patchedTitle: String? = nil,
        description: String = "New Media Description",
        patchedDescription: String? = nil,
        source: String = "New Media Source",
        patchedSource: String? = nil,
        languageId: UUID? = nil,
        waypointId: UUID? = nil,
        verified: Bool = false
    ) async throws -> (mediaRepository: MediaRepositoryModel, createdMediaDescription: MediaDescriptionModel, createdMediaFile: MediaFileModel, patchContent: Media.Media.Patch) {
        let (repository, description, file) = try await createNewMedia(
            title: title,
            description: description,
            source: source,
            verified: verified,
            waypointId: waypointId,
            languageId: languageId
        )
        
        let patchContent = try Media.Media.Patch(
            title: patchedTitle,
            description: patchedDescription,
            source: patchedSource,
            idForMediaToPatch: description.requireID()
        )
        return (repository, description, file, patchContent)
    }
    
    struct TestFile {
        let mimeType: String
        let filename: String
        let fileExtension: String
    }
    
    func testSuccessfulPatchMediaTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, description, file, patchContent) = try await getMediaPatchContent(patchedTitle: "The patched title", verified: true)
        try await description.$language.load(on: app.db)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media title should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertEqual(content.description, description.description)
                XCTAssertEqual(content.source, description.source)
                XCTAssertEqual(content.languageCode, description.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$media
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertFalse(newMediaModel.verified)
    }
    
    func testSuccessfulPatchMediaDescription() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, description, file, patchContent) = try await getMediaPatchContent(patchedDescription: "The patched description", verified: true)
        try await description.$language.load(on: app.db)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media title description return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, description.title)
                XCTAssertEqual(content.description, patchContent.description)
                XCTAssertEqual(content.source, description.source)
                XCTAssertEqual(content.languageCode, description.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$media
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertFalse(newMediaModel.verified)

    }
    
    func testSuccessfulPatchMediaSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, description, file, patchContent) = try await getMediaPatchContent(patchedSource: "The patched source", verified: true)
        try await description.$language.load(on: app.db)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media source should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, description.title)
                XCTAssertEqual(content.description, description.description)
                XCTAssertEqual(content.source, patchContent.source)
                XCTAssertEqual(content.languageCode, description.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$media
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertFalse(newMediaModel.verified)
    }
    
    func testSuccessfulPatchMediaFile() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, description, file, patchContent) = try await getMediaPatchContent(verified: true)
        try await description.$language.load(on: app.db)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        let newFile = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: newFile.filename, withExtension: newFile.fileExtension)
        
        try app
            .describe("Patch media file should return ok")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", newFile.mimeType)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, description.title)
                XCTAssertEqual(content.description, description.description)
                XCTAssertEqual(content.source, description.source)
                XCTAssertEqual(content.languageCode, description.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertNotEqual(content.filePath, file.mediaDirectory)
                XCTAssertNil(content.verified)
            }
            .test()
        
        // Test the new media model was created correctly
        let newMediaModel = try await repository.$media
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newMediaModel.id)
        XCTAssertFalse(newMediaModel.verified)
    }
    
    func testEmptyPatchMediaFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media with empty payload should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchMediaNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedTitle: "", verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media title should need valid title or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchMediaNeedsValidDescription() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedDescription: "", verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media title should need valid description or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchMediaNeedsValidSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedSource: "", verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media title should need valid source or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchMediaNeedsValidIdForMediaToPatch() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, _) = try await getMediaPatchContent(verified: true)
        let patchContent = Media.Media.Patch(title: nil, description: nil, source: nil, idForMediaToPatch: UUID())
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media should need valid id for media to patch or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchMediaFileNeedsValidContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        let newFile = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: newFile.filename, withExtension: newFile.fileExtension)
        
        try app
            .describe("Patch media should need valid content type or abort")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", "hallo/test")
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatfchMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedSource: "Another source", verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media as unverified user should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchMediaWithoutTokenFails() async throws {
        let (repository, _, _, patchContent) = try await getMediaPatchContent(patchedTitle: "My new Title", verified: true)
        
        let query = try URLEncodedFormEncoder().encode(patchContent)
        
        try app
            .describe("Patch media wihtout token should fail")
            .patch(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .expect(.unauthorized)
            .test()
    }
}