//
//  TagApiUpdateTests.swift
//  
//
//  Created by niklhut on 29.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiUpdateTests: AppTestCase, TagTest {
    private func getTagUpdateContent(
        title: String = "New Tag title \(UUID())",
        updatedTitle: String = "Updated Title",
        keywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) }, // array with 5 random numbers between 10 and 100
        updatedKeywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) },
        verified: Bool = false,
        languageId: UUID? = nil,
        updateLanguageCode: String? = nil
    ) async throws -> (repository: TagRepositoryModel, detail: TagDetailModel, updateContent: Tag.Detail.Update) {
        let (repository, detail) = try await createNewTag(
            title: title,
            keywords: keywords,
            verified: verified,
            languageId: languageId
        )
        
        if updateLanguageCode == nil {
            try await detail.$language.load(on: app.db)
        }
        let updateContent = Tag.Detail.Update(
            title: updatedTitle,
            keywords: updatedKeywords,
            languageCode: updateLanguageCode ?? detail.language.languageCode
        )
        return (repository, detail, updateContent)
    }
    
    func testSuccessfulUpdateTag() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, updateContent) = try await getTagUpdateContent(verified: true)
        
        try app
            .describe("Update tag should return ok")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertNotEqual(content.slug, updateContent.title.slugify())
                XCTAssertContains(content.slug, updateContent.title.slugify())
                XCTAssertEqual(content.keywords, updateContent.keywords)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new tag detail was created correctly
        let newTagDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newTagDetail.id)
        XCTAssertNil(newTagDetail.verifiedAt)
    }
    
    func testSuccessfulUpdateTagWithDuplicateTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let title = "My new title \(UUID())"
        let (repository, _, updateContent) = try await getTagUpdateContent(title: title, updatedTitle: title, verified: true)
        
        try app
            .describe("Update tag should return ok")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertNotEqual(content.slug, updateContent.title.slugify())
                XCTAssertContains(content.slug, updateContent.title.slugify())
                XCTAssertEqual(content.keywords, updateContent.keywords)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new tag detail was created correctly
        let newTagDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newTagDetail.id)
        XCTAssertNil(newTagDetail.verifiedAt)
    }
    
    func testSuccessfulUpdateWithNewLanguage() async throws {
        let token = try await getToken(for: .user, verified: true)
        let secondLanguage = try await createLanguage()
        let (repository, _, updateContent) = try await getTagUpdateContent(verified: true, updateLanguageCode: secondLanguage.languageCode)
        
        try app
            .describe("Update tag with new language should return ok")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertNotEqual(content.slug, updateContent.title.slugify())
                XCTAssertContains(content.slug, updateContent.title.slugify())
                XCTAssertEqual(content.keywords, updateContent.keywords)
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
        
        // Test the new tag detail was created correctly
        let newTagDetail = try await repository.$details
            .query(on: app.db)
            .sort(\.$updatedAt, .descending)
            .first()!
        
        XCTAssertNotNil(newTagDetail.id)
        XCTAssertNil(newTagDetail.verifiedAt)
    }
    
    func testUpdateTagAsUnverifiedUserFails() async throws {
        let token = try await getToken(for: .user, verified: false)
        let (repository, _, updateContent) = try await getTagUpdateContent(verified: true)
        
        try app
            .describe("Update tag as unverified user should fail")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateTagWithoutTokenFails() async throws {
        let (repository, _, updateContent) = try await getTagUpdateContent(verified: true)
        
        try app
            .describe("Update tag as unverified user should fail")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateTagNeedsValidTitle() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, _, updateContent) = try await getTagUpdateContent(updatedTitle: "", verified: true)
        
        try app
            .describe("Update tag should require valid title")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateTagIgnoresEmptyKeywords() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository, detail, updateContent) = try await getTagUpdateContent(updatedKeywords: ["hallo", "test", "", "\n", "was ist das", " "], verified: true)
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Update tag should ignore invalid keywords")
            .put(tagPath.appending(repository.requireID().uuidString))
            .body(updateContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertNotNil(content.id)
                XCTAssertEqual(content.title, updateContent.title)
                XCTAssertNotEqual(content.keywords, updateContent.keywords)
                XCTAssertEqual(content.keywords, updateContent.keywords.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                XCTAssertEqual(content.languageCode, updateContent.languageCode)
            }
            .test()
    }
    
    func testUpdateTagNeedsValidLangaugeCode() async throws {
        let token = try await getToken(for: .user, verified: true)
        let (repository1, _, updateContent1) = try await getTagUpdateContent(verified: true, updateLanguageCode: "")
        let (repository2, _, updateContent2) = try await getTagUpdateContent(verified: true, updateLanguageCode: "zz")
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(tagPath.appending(repository1.requireID().uuidString))
            .body(updateContent1)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Update media should need valid language code or fail")
            .put(tagPath.appending(repository2.requireID().uuidString))
            .body(updateContent2)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
