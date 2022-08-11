//
//  MediaApiVerificationTests.swift
//  
//
//  Created by niklhut on 18.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiVerificationTests: AppTestCase, MediaTest {
    func testSuccessfulVerifyMedia() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.slug, detail.title.slugify())
                XCTAssertEqual(content.detailText, detail.detailText)
                XCTAssertEqual(content.source, detail.source)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
                XCTAssertNotNil(content.status)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testVerifyMediaAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        let (repository, detail, _) = try await createNewMedia()
        
        try app
            .describe("Verify media as user should fail")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyMediaWithoutTokenFails() async throws {
        let (repository, detail, _) = try await createNewMedia()
        
        try app
            .describe("Verify media wihtout token should fail")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyMediaWithAlreadyVerifiedMediaFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, _) = try await createNewMedia(status: .verified)
        
        try app
            .describe("Verify media for already verified media should fail")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
