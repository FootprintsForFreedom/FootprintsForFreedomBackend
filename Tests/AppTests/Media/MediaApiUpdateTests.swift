//
//  MediaApiUpdateTests.swift
//  
//
//  Created by niklhut on 16.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Media.Media.Update: Content { }

final class MediaApiUpdateTests: AppTestCase, MediaTest {
    let mediaPath = "api/media/"
    
    private func getMediaUpdateContent(
        title: String = "New Meidia Title \(UUID())",
        updatedTitle: String = "Updated Title",
        description: String = "New Media Description",
        updatedDescription: String = "Updated Description",
        source: String = "New Media Source",
        updatedSource: String = "Updated Media Soruce",
        languageId: UUID? = nil,
        updateLanguageCode: String? = nil,
        waypointId: UUID? = nil,
        setMediaIdForFile: Bool = true,
        verified: Bool = false
    ) async throws -> (mediaRepository: MediaRepositoryModel, createdMediaDescription: MediaDescriptionModel, createdMediaFile: MediaFileModel, updateContent: Media.Media.Update) {
        let (repository, description, file) = try await createNewMedia(
            title: title,
            description: description,
            source: source,
            verified: verified,
            waypointId: waypointId,
            languageId: languageId
        )
        
        if updateLanguageCode == nil {
            try await description.$language.load(on: app.db)
        }
        let updateContent = try Media.Media.Update(
            title: updatedTitle,
            description: updatedDescription,
            source: updatedSource,
            languageCode: updateLanguageCode ?? description.language.languageCode,
            mediaIdForFile: setMediaIdForFile ? description.requireID() : nil
        )
        return (repository, description, file, updateContent)
    }
    
    struct TestFile {
        let mimeType: String
        let filename: String
        let fileExtension: String
    }
    
    func testSuccessfulUpdateMedia() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, file, updateContent) = try await getMediaUpdateContent(verified: true)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.description, updateContent.description)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
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
    
    func testSuccessfulUpdateMediaWithFile() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, file, updateContent) = try await getMediaUpdateContent(setMediaIdForFile: false, verified: true)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        let newFile = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: newFile.filename, withExtension: newFile.fileExtension)
        
        try app
            .describe("Patch media file should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", newFile.mimeType)
            .bearerToken(token)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.description, updateContent.description)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
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
    
    func testSucessfulUpdateWithNewLanguage() async throws {
        let token = try await getToken(for: .user, verified: true)
        let secondLanguage = try await createLanguage(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false)
        let (repository, _, file, updateContent) = try await getMediaUpdateContent(updateLanguageCode: secondLanguage.languageCode, verified: true)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with new language should return ok")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.description, updateContent.description)
                XCTAssertEqual(content.source, updateContent.source)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
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
    
    func testUpdateMediaAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(verified: true)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media as unverified user should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateMediaWithoutTokenFails() async throws {
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(verified: true)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media as unverified user should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateMediaNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(updatedTitle: "", verified: true)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with empty title should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidDescription() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(updatedDescription: "", verified: true)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with empty description should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidSource() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(updatedSource: "", verified: true)
        let query = try URLEncodedFormEncoder().encode(updateContent)
        
        try app
            .describe("Update media with empty source should fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidContentType() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, _, updateContent) = try await getMediaUpdateContent(setMediaIdForFile: false, verified: true)
        
        let query = try URLEncodedFormEncoder().encode(updateContent)
        let newFile = TestFile(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png")
        let fileData = try data(for: newFile.filename, withExtension: newFile.fileExtension)
        
        try app
            .describe("Update media should need valid content type or fail")
            .put(mediaPath.appending("\(repository.requireID().uuidString)/?\(query)"))
            .buffer(ByteBuffer(data: fileData))
            .header("Content-Type", "hallo/test")
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateMediaNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository1, _, _, updateContent1) = try await getMediaUpdateContent(updateLanguageCode: "", verified: true)
        let query1 = try URLEncodedFormEncoder().encode(updateContent1)
        let (repository2, _, _, updateContent2) = try await getMediaUpdateContent(updateLanguageCode: "hi", verified: true)
        let query2 = try URLEncodedFormEncoder().encode(updateContent2)
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(mediaPath.appending("\(repository1.requireID().uuidString)/?\(query1)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(mediaPath.appending("\(repository2.requireID().uuidString)/?\(query2)"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
