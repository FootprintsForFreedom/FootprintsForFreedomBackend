//
//  TagApiGetTests.swift
//  
//
//  Created by niklhut on 29.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiGetTests: AppTestCase, TagTest {
    func testSuccessfulListVerifiedTagsWithPreferredLanguageReturnsVerifiedModelsForAllLanguagesButPrefersSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified tag
        let (unverifiedTagRepository, _) = try await createNewTag(languageId: language.requireID(), userId: userId)
        // Create a verified tag
        let (verifiedTagRepository, createdVerifiedTag) = try await createNewTag(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedTag.$language.load(on: app.db)
        // Create a second not verified model for the verified tag that should not be returned
        let _ = try await TagDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: verifiedTagRepository.requireID(),
            userId: userId,
            on: self
        )
        // Create a repository that is only available in the other language
        let (verifiedTagRepositoryInDifferentLanguage, createdVerifiedTagInDifferentLanguage) = try await createNewTag(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedTagInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedTagRepositoryWithMultipleLanguages, _) = try await createNewTag(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedTagInLanguage1 = try await TagDetailModel.createWith(
            verified: true,
            title: "Language 2 \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: verifiedTagRepositoryWithMultipleLanguages.requireID(),
            userId: userId,
            on: self
        )
        try await createdVerifiedTagInLanguage1.$language.load(on: app.db)
        
        // Get verified tag count
        let tag = try await TagRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .all()
        
        let tagCount = tag.count
        
        let verifiedTagCount = tag
            .filter { $0.details.contains { $0.verifiedAt != nil && $0.language.priority != nil } }
            .count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List tag with perferred language should return ok and verified models for all languages. However, it should prefer the specified language")
            .get(tagPath.appending("?preferredLanguage=\(language.languageCode)&per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, verifiedTagCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, verifiedTagCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedTagCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedTagRepository.id })
                if let verifiedTag = content.items.first(where: { $0.id == verifiedTagRepository.id }) {
                    XCTAssertEqual(verifiedTag.id, verifiedTagRepository.id)
                    XCTAssertEqual(verifiedTag.title, createdVerifiedTag.title)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedTagRepositoryInDifferentLanguage.id })
                if let verifiedTagInDifferentLanguage = content.items.first(where: { $0.id == verifiedTagRepositoryInDifferentLanguage.id }) {
                    XCTAssertEqual(verifiedTagInDifferentLanguage.id, verifiedTagRepositoryInDifferentLanguage.id)
                    XCTAssertEqual(verifiedTagInDifferentLanguage.title, createdVerifiedTagInDifferentLanguage.title)
                }
                    
                XCTAssert(content.items.contains { $0.id == verifiedTagRepositoryWithMultipleLanguages.id })
                if let verifiedTagWithMultipleLanguages = content.items.first(where: { $0.id == verifiedTagRepositoryWithMultipleLanguages.id }) {
                    XCTAssertEqual(verifiedTagWithMultipleLanguages.id, verifiedTagRepositoryWithMultipleLanguages.id)
                    XCTAssertEqual(verifiedTagWithMultipleLanguages.title, createdVerifiedTagInLanguage1.title)
                }
                XCTAssert(!content.items.contains { $0.id == unverifiedTagRepository.id })
            }
            .test()
    }
    
    func testSuccessfulListVerifiedTagsWithoutPreferredLanguageReturnsVerifiedModlesForAllLanguagesAccordingToTheirPriority() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified tag
        let (unverifiedTagRepository, _) = try await createNewTag(languageId: language.requireID(), userId: userId)
        // Create a verified tag
        let (verifiedTagRepository, createdVerifiedTag) = try await createNewTag(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified tag that should not be returned
        let _ = try await TagDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: verifiedTagRepository.requireID(),
            userId: userId,
            on: self
        )
        // Create a repository that is only available in the other language
        let (verifiedTagRepositoryInDifferentLanguage, createdVerifiedTagInDifferentLanguage) = try await createNewTag(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedTagInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedTagRepositoryWithMultipleLanguages, _) = try await createNewTag(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedTagInLanguage1 = try await TagDetailModel.createWith(
            verified: true,
            title: "Language 2 \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: verifiedTagRepositoryWithMultipleLanguages.requireID(),
            userId: userId,
            on: self
        )
        // Get verified tag count
        let tag = try await TagRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .all()
        
        let tagCount = tag.count
        
        let verifiedTagCount = tag
            .filter { $0.details.contains { $0.verifiedAt != nil && $0.language.priority != nil } }
            .count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List tag should return ok")
            .get(tagPath.appending("?per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssertEqual(content.items.count, verifiedTagCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedTagRepository.id })
                if let verifiedTag = content.items.first(where: { $0.id == verifiedTagRepository.id }) {
                    XCTAssertEqual(verifiedTag.id, verifiedTagRepository.id)
                    XCTAssertEqual(verifiedTag.title, createdVerifiedTag.title)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedTagRepositoryInDifferentLanguage.id })
                if let verifiedTagInDifferentLanguage = content.items.first(where: { $0.id == verifiedTagRepositoryInDifferentLanguage.id }) {
                    XCTAssertEqual(verifiedTagInDifferentLanguage.id, verifiedTagRepositoryInDifferentLanguage.id)
                    XCTAssertEqual(verifiedTagInDifferentLanguage.title, createdVerifiedTagInDifferentLanguage.title)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedTagRepositoryWithMultipleLanguages.id })
                if let verifiedTagWithMultipleLanguages = content.items.first(where: { $0.id == verifiedTagRepositoryWithMultipleLanguages.id }) {
                    XCTAssertEqual(verifiedTagWithMultipleLanguages.id, verifiedTagRepositoryWithMultipleLanguages.id)
                    XCTAssertEqual(verifiedTagWithMultipleLanguages.title, createdVerifiedTagInLanguage1.title)
                }
                
                XCTAssert(!content.items.contains { $0.id == unverifiedTagRepository.id })
            }
            .test()
    }
    
    func testSuccessfulListVerifiedTagsDoesNotReturnModelsForDeactivatedLanguages() async throws {
        let language = try await createLanguage()
        let deactivatedLanguage = try await createLanguage()
        let userId = try await getUser(role: .user).requireID()
        
        // Create a verified tag
        let (verifiedTagRepository, _) = try await createNewTag(verified: true, languageId: language.requireID(), userId: userId)
        
        // Create a tag for a deactivated language
        let (verifiedTagRepositoryForDeactivatedLanguage, _) = try await createNewTag(verified: true, languageId: deactivatedLanguage.requireID(), userId: userId)
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        // Get tag count
        let tag = try await TagRepositoryModel
            .query(on: app.db)
            .with(\.$details)
            .all()
        
        let tagCount = tag.count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List tag should return ok")
            .get(tagPath.appending("?per=\(tagCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Tag.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == verifiedTagRepository.id })
                XCTAssertFalse(content.items.contains { $0.id == verifiedTagRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedTag() async throws {
        let (repository, detail) = try await createNewTag(verified: true)
        try await detail.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified tag should return ok")
            .get(tagPath.appending(repository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.slug, detail.slug)
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedTagAsModerator() async throws {
        let (repository, detail) = try await createNewTag(verified: true)
        try await detail.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified tag should return ok")
            .get(tagPath.appending(repository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, detail.id!)
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedTagBySlug() async throws {
        let (repository, detail) = try await createNewTag(verified: true)
        try await detail.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified tag by slug should return ok")
            .get(tagPath.appending("find/\(detail.slug)"))
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, repository.id)
                XCTAssertEqual(content.title, detail.title)
                XCTAssertEqual(content.slug, detail.slug)
                XCTAssertEqual(content.keywords, detail.keywords)
                XCTAssertEqual(content.languageCode, detail.language.languageCode)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testGetTagForDeactivatedLanguageFails() async throws {
        let deactivatedLanguage = try await createLanguage()
        let (repositoryForDeactivatedLanguage, _) = try await createNewTag(verified: true, languageId: deactivatedLanguage.requireID())
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified for deactivated language should fail")
            .get(tagPath.appending(repositoryForDeactivatedLanguage.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }
    
    func testGetUnverifiedTagFails() async throws {
        let (repository, _) = try await createNewTag()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get unverified tag should fail")
            .get(tagPath.appending(repository.requireID().uuidString))
            .expect(.notFound)
            .test()
    }
}
