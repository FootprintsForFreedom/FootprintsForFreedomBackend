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
    let mediaPath = "api/media/"
    
    func testSuccessfulVerifyMedia() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, description, file) = try await createNewMedia()
        try await description.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(description.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Media.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, description.title)
                XCTAssertEqual(content.description, description.description)
                XCTAssertEqual(content.source, description.source)
                XCTAssertEqual(content.languageCode, description.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.mediaDirectory)
                XCTAssertEqual(content.verified, true)
            }
            .test()
    }
    
    func testVerifyMediaAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        let (repository, description, _) = try await createNewMedia()
        
        try app
            .describe("Verify media as user should fail")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(description.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyMediaWithoutTokenFails() async throws {
        let (repository, description, _) = try await createNewMedia()
        
        try app
            .describe("Verify media wihtout token should fail")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(description.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyMediaWithAlreadyVerifiedMediaFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, description, _) = try await createNewMedia(verified: true)
        
        try app
            .describe("Verify media for already verified media should fail")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(description.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
