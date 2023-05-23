//
//  TagApiSearchTests.swift
//  
//
//  Created by niklhut on 04.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiSearchTests: AppTestCase, TagTest {
    func testSuccessfulSearchTagReturnsWhenTextInTitle() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Search tag should return the tag if it is verified and has the search text in the title")
            .get(tagPath.appending("search/?text=besonder&languageCode=\(tag.detail.language.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == tag.repository.id })
                guard let searchedTag = content.items.first(where: { $0.id == tag.repository.id }) else {
                    XCTFail("Could not find searched tag")
                    return
                }
                XCTAssertEqual(searchedTag.title, tag.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchTagReturnsWhenTextInKeywords() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Search tag should return the tag if it is verified and has the search text in the keywords")
            .get(tagPath.appending("search/?text=ander&languageCode=\(tag.detail.language.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == tag.repository.id })
                guard let searchedTag = content.items.first(where: { $0.id == tag.repository.id }) else {
                    XCTFail("Could not find searched tag")
                    return
                }
                XCTAssertEqual(searchedTag.title, tag.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchTagOnlyReturnsVerifiedTags() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"])
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search tag should not return the tag if it is unverified")
            .get(tagPath.appending("search/?text=ander&languageCode=\(tag.detail.language.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchTagDoesNotReturnWhenTextNotInTitleOrKeywords() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search tag should not return the tag if it is verified but does not have the search text in the title or keywords")
            .get(tagPath.appending("search/?text=hallo&languageCode=\(tag.detail.language.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchTagOnlyReturnsDetailsForSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search tag should only return tags for the specified language")
            .get(tagPath.appending("search/?text=ander&languageCode=\(language2.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchTagDoesNotReturnDetailsForDeactivatedLanguage() async throws {
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
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search tag should only return tags for the specified language")
            .get(tagPath.appending("search/?text=ander&languageCode=\(language.languageCode)&per=\(tagCount)"))
            .expect(.notFound)
            .test()
    }
    
    func testSuccessfulSearchTagOnlyReturnsNewestVerifiedDetailForRepository() async throws {
        let language = try await createLanguage()
        let userId = try await getUser(role: .user).requireID()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true, languageId: language.requireID())
        let newerTag = try await TagDetailModel.createWith(
            verified: true,
            title: "Ein besonderer Titel neu",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: userId,
            on: self
        )
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Search tag should only return the newest verified detail for a tag repository")
            .get(tagPath.appending("search/?text=besonderer&languageCode=\(language.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == tag.repository.id })
                guard let searchedTag = content.items.first(where: { $0.id == tag.repository.id }) else {
                    XCTFail("Could not find searched tag")
                    return
                }
                XCTAssertEqual(searchedTag.title, newerTag.title)
                XCTAssertNotEqual(searchedTag.title, tag.detail.title)
                XCTAssert(!content.items.contains(where: { $0.title == tag.detail.title }))
                XCTAssert(content.items.contains(where: { $0.title == newerTag.title }))
            }
            .test()
    }
    
    func testSearchTagNeedsValidText() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search tag should return the text query field is empty")
            .get(tagPath.appending("search/?text=&languageCode=\(tag.detail.language.languageCode)&per=\(tagCount)"))
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Search tag should return the text query field is only a whitespace or a newline")
            .get(tagPath.appending("search/?text=%20\n&languageCode=\(tag.detail.language.languageCode)&per=\(tagCount)"))
            .expect(.badRequest)
            .test()
    }
    
    func testSearchTagNeedsValidLanguageCode() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], verified: true)
        try await tag.detail.$language.load(on: app.db)
        
        let tagCount = try await TagRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search tag should return the text query field is empty")
            .get(tagPath.appending("search/?text=bes&per=\(tagCount)"))
            .expect(.badRequest)
            .test()
    }
}
