//
//  StaticContentApiCreateTests.swift
//  
//
//  Created by niklhut on 10.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension StaticContent.Detail.Create: Content { }

final class StaticContentApiCreateTests: AppTestCase, StaticContentTest {
    private func getStaticContentCreateContent(
        repositoryTitle: String = "New text \(UUID())",
        moderationTitle: String = "Moderation title \(UUID())",
        requiredSnippets: [StaticContent.Snippet] = [],
        title: String = "New StaticContent title \(UUID())",
        text: String = "This is a text",
        languageCode: String? = nil
    ) async throws -> StaticContent.Detail.Create {
        var languageCode: String! = languageCode
        if languageCode == nil {
            languageCode = try await createLanguage().languageCode
        }
        return .init(repositoryTitle: repositoryTitle, moderationTitle: moderationTitle, title: title, text: text, requiredSnippets: requiredSnippets, languageCode: languageCode)
    }
    
    func testSuccessfulCreateStaticContentAsAdmin() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent()
        
        try app
            .describe("Create staticContent as admin should return ok")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.created)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newStaticContent.title)
                XCTAssertEqual(content.text, newStaticContent.text)
                XCTAssertEqual(content.languageCode, newStaticContent.languageCode)
            }
            .test()
    }
    
    func testSuccessfulCreateStaticContentWithRequiredSnippets() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent(requiredSnippets: StaticContent.Snippet.allCases, text: "My text with \(StaticContent.Snippet.allCases.map(\.rawValue))")
        
        try app
            .describe("Create staticContent as admin with required snippets should return ok")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.created)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newStaticContent.title)
                XCTAssertEqual(content.text, newStaticContent.text)
                XCTAssertEqual(content.languageCode, newStaticContent.languageCode)
            }
            .test()
    }
    
    func testSuccessfulCreateStaticContentWithoutRequiredSnippets() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        struct Create: Content {
            let repositoryTitle: String
            let moderationTitle: String
            let title: String
            let text: String
            let languageCode: String
        }
        let languageCode = try await createLanguage().languageCode
        let newStaticContent = Create(repositoryTitle: "My title \(UUID())", moderationTitle: "Some moderation title \(UUID())", title: "The localized title \(UUID())", text: "Hello hello", languageCode: languageCode)
        
        try app
            .describe("Create staticContent as admin with required snippets should return ok")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.created)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newStaticContent.title)
                XCTAssertEqual(content.text, newStaticContent.text)
                XCTAssertEqual(content.languageCode, newStaticContent.languageCode)
            }
            .test()
    }
    
    func testSuccessfulCreateStaticContentWithDuplicateTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let staticContent = try await createNewStaticContent()
        let newStaticContent = try await getStaticContentCreateContent(title: staticContent.detail.title)
        
        try app
            .describe("Create staticContent with duplicate title should return ok")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.created)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newStaticContent.title)
                XCTAssertEqual(content.text, newStaticContent.text)
                XCTAssertEqual(content.languageCode, newStaticContent.languageCode)
            }
            .test()
    }
    
    func testCreateStaticContentWithDuplicateRepositoryTitleFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let repositoryTitle = "My title \(UUID())"
        let _ = try await createNewStaticContent(repositoryTitle: repositoryTitle)
        let newStaticContent = try await getStaticContentCreateContent(repositoryTitle: repositoryTitle)
        
        try app
            .describe("Create staticContent with duplicate repository title should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateStaticContentWithInvalidSnippetsFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        
        struct Create: Content {
            let repositoryTitle: String
            let title: String
            let text: String
            let requiredSnippets: [String]
            let languageCode: String
        }
        let languageCode = try await createLanguage().languageCode
        let newStaticContent = Create(repositoryTitle: "My title \(UUID())", title: "The localized title \(UUID())", text: "Hello hello", requiredSnippets: ["someSnippet"], languageCode: languageCode)
        
        try app
            .describe("Create staticContent with invalid snippets should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateStaticContentAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator, verified: true)
        let newStaticContent = try await getStaticContentCreateContent()
        
        try app
            .describe("Create staticContent as moderator should should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateStaticContentWithoutRequiredSnippetsInTextFails() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent(requiredSnippets: StaticContent.Snippet.allCases, text: "My text without snippets")
        
        try app
            .describe("Create staticContent as admin with required snippets should return ok")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateStaticContentWithoutTokenFails() async throws {
        let newStaticContent = try await getStaticContentCreateContent()
        
        try app
            .describe("Create staticContent without token should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateStaticContentNeedsValidRepositoryTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent(repositoryTitle: "")
        
        try app
            .describe("Create staticContent with empty repository title should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateStaticContentNeedsValidModerationTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent(moderationTitle: "")
        
        try app
            .describe("Create staticContent with empty repository title should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateStaticContentNeedsValidTitle() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent(title: "")
        
        try app
            .describe("Create staticContent with empty title should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateStaticContentNeedsValidKeywords() async throws {
        let token = try await getToken(for: .admin, verified: true)
        let newStaticContent = try await getStaticContentCreateContent(text: "")
        
        try app
            .describe("Create staticContent with empty text should fail")
            .post(staticContentPath)
            .body(newStaticContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
