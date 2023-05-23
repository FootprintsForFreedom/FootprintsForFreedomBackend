//
//  TagApiSuggestTests.swift
//  
//
//  Created by niklhut on 24.10.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiSuggestTests: AppTestCase, TagTest {
    func testSuccessfulSuggestTagReturnsWhenTextPrefixOfTitle() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Search tag should return the tag if it is verified and has the suggest text in the title")
            .get(tagPath.appending("suggest/?text=ein&languageCode=\(tag.detail.language.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Detail.List].self) { content in
                XCTAssert(content.contains { $0.id == tag.repository.id })
                guard let suggestedTag = content.first(where: { $0.id == tag.repository.id }) else {
                    XCTFail("Could not find suggested tag")
                    return
                }
                XCTAssertEqual(suggestedTag.title, tag.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSuggestTagOnlyReturnsVerifiedTags() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"])
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Search tag should not return the tag if it is unverified")
            .get(tagPath.appending("suggest/?text=ander&languageCode=\(tag.detail.language.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSuggestTagDoesNotReturnWhenTextNotInTitle() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Search tag should not return the tag if it is verified but does not have the suggest text in the title or keywords")
            .get(tagPath.appending("suggest/?text=anders&languageCode=\(tag.detail.language.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSuggestTagOnlyReturnsForSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Search tag should only return tags for the specified language")
            .get(tagPath.appending("suggest/?text=ander&languageCode=\(language2.languageCode)"))
            .expect(.ok)
            .expect(.json)
            .expect([Tag.Detail.List].self) { content in
                XCTAssert(!content.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSuggestTagDoesNotReturnDetailsForDeactivatedLanguage() async throws {
        let language = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        try await tag.detail.$language.load(on: app.db)
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Search tag should only return tags for the specified language")
            .get(tagPath.appending("suggest/?text=ander&languageCode=\(language.languageCode)"))
            .expect(.notFound)
            .test()
    }
    
    func testSuggestTagNeedsValidText() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest tag should return the text query field is empty")
            .get(tagPath.appending("suggest/?text=&languageCode=\(tag.detail.language.languageCode)"))
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Suggest tag should return the text query field is only a whitespace or a newline")
            .get(tagPath.appending("suggest/?text=%20\n&languageCode=\(tag.detail.language.languageCode)"))
            .expect(.badRequest)
            .test()
    }
    
    func testSuggestTagNeedsValidLanguageCode() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Suggest tag should return the text query field is empty")
            .get(tagPath.appending("suggest/?text=bes"))
            .expect(.badRequest)
            .test()
    }
}
