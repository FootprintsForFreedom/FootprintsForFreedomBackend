//
//  TagApiCreateTests.swift
//  
//
//  Created by niklhut on 27.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Tag.Detail.Create: Content { }

final class TagApiCreateTests: AppTestCase, TagTest {
    private func getTagCreateContent(
        title: String = "New Tag title \(UUID())",
        keywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) }, // array with 5 random numbers between 10 and 100
        languageCode: String? = nil
    ) async throws -> Tag.Detail.Create {
        var languageCode: String! = languageCode
        if languageCode == nil {
            languageCode = try await createLanguage().languageCode
        }
        return .init(title: title, keywords: keywords, languageCode: languageCode)
    }
    
    func testSuccessfulCreateTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newTag = try await getTagCreateContent()
        
        try app
            .describe("Create tag as verified user should return ok")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.created)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newTag.title)
                XCTAssertNotEqual(content.slug, newTag.title.slugify())
                XCTAssertContains(content.slug, newTag.title.slugify())
                XCTAssertEqual(content.keywords, newTag.keywords)
                XCTAssertEqual(content.languageCode, newTag.languageCode)
            }
            .test()
    }
    
    func testSuccessfulCreateTagAsModerator() async throws {
        let token = try await getToken(for: .moderator, verified: true)
        let newTag = try await getTagCreateContent()
            
        try app
            .describe("Create tag as moderator should return ok")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.created)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newTag.title)
                XCTAssertNotEqual(content.slug, newTag.title.slugify())
                XCTAssertContains(content.slug, newTag.title.slugify())
                XCTAssertEqual(content.keywords, newTag.keywords)
                XCTAssertEqual(content.languageCode, newTag.languageCode)
            }
            .test()
    }
    
    func testSuccessfulCreateTagWithDuplicateTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let tag = try await createNewTag()
        let newTag = try await getTagCreateContent(title: tag.detail.title)
        
        try app
            .describe("Create tag with duplicate title should return ok")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.created)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newTag.title)
                XCTAssertNotEqual(content.slug, newTag.title.slugify())
                XCTAssertContains(content.slug, newTag.title.slugify())
                XCTAssertEqual(content.keywords, newTag.keywords)
                XCTAssertEqual(content.languageCode, newTag.languageCode)
            }
            .test()
    }
    
    func testCreateTagAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let newTag = try await getTagCreateContent()
            
        try app
            .describe("Create tag as unverified user should should fail")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateTagWithoutTokenFails() async throws {
        let newTag = try await getTagCreateContent()
            
        try app
            .describe("Create tag without token should fail")
            .post(tagPath)
            .body(newTag)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateTagNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newTag = try await getTagCreateContent(title: "")
            
        try app
            .describe("Create tag with empty title should fail")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateTagNeedsValidKeywords() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newTag = try await getTagCreateContent(keywords: [String]())
            
        try app
            .describe("Create tag with empty keywords should fail")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        let newTag2 = try await getTagCreateContent(keywords: [""])
        
        try app
            .describe("Create tag with empty keywords should fail")
            .post(tagPath)
            .body(newTag2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateTagIgnoresEmptyKeywords() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newTag = try await getTagCreateContent(keywords: ["hallo", "test", "", "\n", "was ist das", " "])
        
        try app
            .describe("Create tag as verified user should return ok and ignore empty keywords")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.created)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, newTag.title)
                XCTAssertNotEqual(content.keywords, newTag.keywords)
                XCTAssertEqual(content.keywords, newTag.keywords.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                XCTAssertEqual(content.languageCode, newTag.languageCode)
            }
            .test()
    }
    
    func testCreateTagNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .user, verified: true)
        let newTag1 = try await getTagCreateContent(languageCode: "")
        let newTag2 = try await getTagCreateContent(languageCode: "zz")
        
        try app
            .describe("Create waypoint with empty language code should fail")
            .post(tagPath)
            .body(newTag1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Create waypoint with non-existent language code should fail")
            .post(tagPath)
            .body(newTag2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateTagForDeactivatedLanguageFails() async throws {
        let token = try await getToken(for: .user, verified: true)
        let language = try await createLanguage(activated: false)
        let newTag = try await getTagCreateContent(languageCode: language.languageCode)
        
        try app
            .describe("Create tag for deactivated language code should fail")
            .post(tagPath)
            .body(newTag)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
