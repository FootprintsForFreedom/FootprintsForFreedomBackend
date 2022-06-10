//
//  StaticContentApiPatchTests.swift
//  
//
//  Created by niklhut on 10.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension StaticContent.Detail.Patch: Content { }

final class StaticContentApiPatchTests: AppTestCase, StaticContentTest {
    private func getStaticContentPatchContent(
        repositoryTitle: String = "New title \(UUID())",
        title: String = "New StaticContent title \(UUID())",
        patchedTitle: String? = nil,
        text: String = "This is a text",
        patchedText: String? = nil,
        languageId: UUID? = nil
    ) async throws -> (repository: StaticContentRepositoryModel, detail: StaticContentDetailModel, patchContent: StaticContent.Detail.Patch) {
        let (repository, detail) = try await createNewStaticContent(
            repositoryTitle: repositoryTitle,
            title: title,
            text: text,
            languageId: languageId
        )
        
        let patchContent = try StaticContent.Detail.Patch(
            title: patchedTitle,
            text: patchedText,
            idForStaticContentDetailToPatch: detail.requireID()
        )
        return (repository, detail, patchContent)
    }
    
    func testSuccessfulPatchStaticContentTitleAsAdmin() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let (repository, detail, patchContent) = try await getStaticContentPatchContent(patchedTitle: "The patched title")
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Patch staticContent title should return ok")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertEqual(content.text, detail.text)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }
    
    func testSuccessfulPatchStaticContentTitleWithDuplicateTitle() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let title = "My new title \(UUID())"
        let (repository, detail, patchContent) = try await getStaticContentPatchContent(title: title, patchedTitle: title)
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Patch staticContent title should return ok")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, patchContent.title)
                XCTAssertEqual(content.text, detail.text)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }
    
    func testSuccessfulPatchStaticContentText() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let (repository, detail, patchContent) = try await getStaticContentPatchContent(patchedText: "This is a new text")
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Patch staticContent text should return ok")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.text, patchContent.text)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
            }
            .test()
    }
    
    func testPatchStaticContentTitleAsModeratorFails() async throws {
        let moderatorToken = try await getToken(for: .moderator, verified: true)
        let (repository, detail, patchContent) = try await getStaticContentPatchContent(patchedTitle: "The patched title")
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Patch staticContent title should return ok")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }
    
    func testEmptyPatchStaticContentFails() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let (repository, _, patchContent) = try await getStaticContentPatchContent()
        
        try app
            .describe("Patch staticContent with empty body should fail")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchStaticContentNeedsValidTitle() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let (repository, _, patchContent) = try await getStaticContentPatchContent(patchedTitle: "")
        
        try app
            .describe("Patch staticContent title should require valid title")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchStaticContentNeedsValidText() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let (repository, _, patchContent) = try await getStaticContentPatchContent(patchedText: "")
        
        try app
            .describe("Patch staticContent title should require valid text")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchStaticContentNeedsValidIdForStaticContentToPatch() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let (repository, _, _) = try await getStaticContentPatchContent()
        let patchContent = StaticContent.Detail.Patch(title: "New Title", text: nil, idForStaticContentDetailToPatch: UUID())
        
        try app
            .describe("Patch staticContent title should require valid id for staticContent to patch")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .bearerToken(adminToken)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchStaticContentWithoutTokenFails() async throws {
        let (repository, _, patchContent) = try await getStaticContentPatchContent(patchedTitle: "The patched title")
        
        try app
            .describe("Patch staticContent title should return ok")
            .patch(staticContentPath.appending(repository.requireID().uuidString))
            .body(patchContent)
            .expect(.unauthorized)
            .test()
    }
}
