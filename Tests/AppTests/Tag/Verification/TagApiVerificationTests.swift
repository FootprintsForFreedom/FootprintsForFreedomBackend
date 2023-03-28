//
//  TagApiVerificationTests.swift
//  
//
//  Created by niklhut on 29.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiVerificationTests: AppTestCase, TagTest {
    func testSuccessfulVerifyTag() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail) = try await createNewTag()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.slug, detail.title.slugify())
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }
    
    func testVerifyTagWithDeactivatedLanguageFails() async throws {
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify tag with deactivated language should fail")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()

    }
    
    func testVerifyTagAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        let (repository, detail) = try await createNewTag()
        
        try app
            .describe("Verify tag as user should fail")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyTagWithoutTokenFails() async throws {
        let (repository, detail) = try await createNewTag()
        
        try app
            .describe("Verify tag as user should fail")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyTagWithAlreadyVerifiedTagFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail) = try await createNewTag(verified: true)
        
        try app
            .describe("Verify tag for already verified tag should fail")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
