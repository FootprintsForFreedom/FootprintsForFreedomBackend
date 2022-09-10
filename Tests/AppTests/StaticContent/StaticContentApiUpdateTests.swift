//
//  StaticContentApiUpdateTests.swift
//  
//
//  Created by niklhut on 10.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension StaticContent.Detail.Update: Content { }

final class StaticContentApiUpdateTests: AppTestCase, StaticContentTest {
    private func getStaticContentUpdateContent(
        repositoryTitle: String = "New title \(UUID())",
        requiredSnippets: [StaticContent.Snippet] = [],
        moderationTitle: String = "Moderation title \(UUID())",
        updatedModerationTitle: String = "New Moderation title \(UUID())",
        title: String = "New StaticContent title \(UUID())",
        updatedTitle: String = "Updated Title",
        text: String = "This is a text",
        updatedText: String = "This is a new Text",
        languageId: UUID? = nil,
        updateLanguageCode: String? = nil
    ) async throws -> (repository: StaticContentRepositoryModel, detail: StaticContentDetailModel, updateContent: StaticContent.Detail.Update) {
        let (repository, detail) = try await createNewStaticContent(
            repositoryTitle: repositoryTitle,
            requiredSnippets: requiredSnippets,
            moderationTitle: moderationTitle,
            title: title,
            text: text,
            languageId: languageId
        )
        
        if updateLanguageCode == nil {
            try await detail.$language.load(on: app.db)
        }
        let updateContent = StaticContent.Detail.Update(
            moderationTitle: updatedModerationTitle,
            title: updatedTitle,
            text: updatedText,
            languageCode: updateLanguageCode ?? detail.language.languageCode
        )
        return (repository, detail, updateContent)
    }
    
    func testSuccessfulUpdateStaticContent() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent()
        
        try app
            .describe("Update staticContent should return ok")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.text, updateContent.text)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new staticContent detail was created correctly
        let newStaticContentDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newStaticContentDetail.id)
        XCTAssertNotNil(newStaticContentDetail.verifiedAt)
    }
    
    func testSuccessfulUpdateStaticContentWithRequiredSnippets() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(requiredSnippets: StaticContent.Snippet.allCases, updatedText: "This is a new text with \(StaticContent.Snippet.allCases.map(\.rawValue))")
        
        try app
            .describe("Update staticContent should return ok")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.text, updateContent.text)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new staticContent detail was created correctly
        let newStaticContentDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newStaticContentDetail.id)
        XCTAssertNotNil(newStaticContentDetail.verifiedAt)
    }
    
    func testSuccessfulUpdateStaticContentWithDuplicateTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let title = "My new title \(UUID())"
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(title: title, updatedTitle: title)
        
        try app
            .describe("Update staticContent should return ok")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.text, updateContent.text)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new staticContent detail was created correctly
        let newStaticContentDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newStaticContentDetail.id)
        XCTAssertNotNil(newStaticContentDetail.verifiedAt)
    }
    
    func testSuccessfulUpdateWithNewLanguage() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let secondLanguage = try await createLanguage()
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(updateLanguageCode: secondLanguage.languageCode)
        
        try app
            .describe("Update staticContent with new language should return ok")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertEqual(content.text, updateContent.text)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new staticContent detail was created correctly
        let newStaticContentDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newStaticContentDetail.id)
        XCTAssertNotNil(newStaticContentDetail.verifiedAt)
    }
    
    func testUpdateStaticContentWithoutRequiredSnippetsInTextFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(requiredSnippets: StaticContent.Snippet.allCases, updatedText: "This is a new text without snippets")
        
        try app
            .describe("Update staticContent should return ok")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateStaticContentAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator, verified: false)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent()
        
        try app
            .describe("Update staticContent as unverified user should fail")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateStaticContentWithoutTokenFails() async throws {
        let (repository, _, updateContent) = try await getStaticContentUpdateContent()
        
        try app
            .describe("Update staticContent as unverified user should fail")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateStaticContentNeedsValidModerationTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(updatedModerationTitle: "")
        
        try app
            .describe("Update staticContent should require valid title")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateStaticContentNeedsValidTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(updatedTitle: "")
        
        try app
            .describe("Update staticContent should require valid title")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateStaticContentNeedsValidText() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository, _, updateContent) = try await getStaticContentUpdateContent(updatedText: "")
        
        try app
            .describe("Update staticContent should require valid text")
            .put(staticContentPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateStaticContentNeedsValidLangaugeCode() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let (repository1, _, updateContent1) = try await getStaticContentUpdateContent(updateLanguageCode: "")
        let (repository2, _, updateContent2) = try await getStaticContentUpdateContent(updateLanguageCode: "hi")
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(staticContentPath.appending(repository1.requireID().uuidString))
            .body(updateContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(staticContentPath.appending(repository2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
