//
//  TagApiListUnverifiedTests.swift
//  
//
//  Created by niklhut on 29.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiListUnverifiedTests: AppTestCase, TagTest {
    func testSuccessfulListRepositoriesWithUnverifiedModels() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let deactivatedLanguage = try await createLanguage(activated: false)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified tag
        let (unverifiedTagRepository, createdUnverifiedDetail) = try await createNewTag(languageId: language.requireID(), userId: userId)
        // Create an unverified tag for a deactivated language
        let (unverifiedTagRepositoryForDeactivatedLanguage, _) = try await createNewTag(languageId: deactivatedLanguage.requireID(), userId: userId)
        // Create a verified tag
        let (verifiedTagRepository, createdVerifiedDetail) = try await createNewTag(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified tag
        let _ = try await TagDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: verifiedTagRepository.requireID(),
            userId: userId,
            on: self
        )
        // Create a tag in the other language
        let (verifiedTagRepositoryInDifferentLanguage, _) = try await createNewTag(verified: true, languageId: language2.requireID(), userId: userId)
        
        // Get unverified tag count
        let tag = try await TagRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .all()
        
        let tagCount = tag.count
        
        let unverifiedTagCount = tag
            .filter { $0.details.contains { $0.verifiedAt == nil && $0.language.priority != nil } }
            .count
        
        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(tagPath.appending("unverified/?preferredLanguage=\(language.languageCode)&per=\(tagCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Tag.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedTagCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, unverifiedTagCount)
                XCTAssert(content.items.map { $0.id }.uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedTagCount)
                
                XCTAssert(content.items.contains { $0.id == unverifiedTagRepository.id })
                if let unverifiedTag = content.items.first(where: { $0.id == unverifiedTagRepository.id }) {
                    XCTAssertEqual(unverifiedTag.id, unverifiedTagRepository.id)
                    XCTAssertEqual(unverifiedTag.title, createdUnverifiedDetail.title)
                }
                
                // contains the verified tag repository because it has a second unverified tag model
                // here it should also return the verified model in the list for preview to see which tag was edited
                XCTAssert(content.items.contains { $0.id == verifiedTagRepository.id })
                if let verifiedTag = content.items.first(where: { $0.id == verifiedTagRepository.id }) {
                    XCTAssertEqual(verifiedTag.id, verifiedTagRepository.id)
                    XCTAssertEqual(verifiedTag.title, createdVerifiedDetail.title)
                }
                
                XCTAssertFalse(content.items.contains { $0.id == verifiedTagRepositoryInDifferentLanguage.id })
                XCTAssertFalse(content.items.contains { $0.id == unverifiedTagRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }
    
    func testListRepositoriesWithUnverifiedModelsAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("List repositories with unverified models as user should fail")
            .get(tagPath.appending("unverified"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListRepositoriesWithUnverifiedModelsWithoutTokenFails() async throws {
        try app
            .describe("List repositories with unverified without token should fail")
            .get(tagPath.appending("unverified"))
            .expect(.unauthorized)
            .test()
    }
    
    func testListUnverifiedDetailsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let deactivatedLanguage = try await createLanguage(activated: false)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified tag
        let (tagRepository, createdUnverifiedDetail) = try await createNewTag(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedDetail.$language.load(on: app.db)
        // Create a verified tag for the same repository
        let verifiedDetail = try await TagDetailModel.createWith(
            verified: true,
            title: "Verified Tag \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: tagRepository.requireID(),
            userId: userId,
            on: self
        )
        // Create a second not verified tag for the same repository
        let secondCreatedUnverifiedDetail = try await TagDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: tagRepository.requireID(),
            userId: userId,
            on: self
        )
        // Create an unverified tag for the same repository but with a deactivated language
        let unverifiedDetailForDeactivatedLanguage = try await TagDetailModel.createWith(
            verified: false,
            title: "Unverified Tag for deactivated language \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: deactivatedLanguage.requireID(),
            repositoryId: tagRepository.requireID(),
            userId: userId,
            on: self
        )
        try await secondCreatedUnverifiedDetail.$language.load(on: app.db)
        // Create a second not verified tag for the same repository in another language
        let createdUnverifiedDetailInDifferentLanguage = try await TagDetailModel.createWith(
            verified: false,
            title: "Different language \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language2.requireID(),
            repositoryId: tagRepository.requireID(),
            userId: userId,
            on: self
        )
        try await createdUnverifiedDetailInDifferentLanguage.$language.load(on: app.db)
        // Create a not verified tag for another repository
        let (_, unverifiedDetailForDifferentRepository) = try await createNewTag(languageId: language.requireID(), userId: userId)
        
        // Get unverified and verified tag count
        let tagCount = try await TagDetailModel
            .query(on: app.db)
            .count()
        
        let unverifiedTagForRepositoryCount = try await TagDetailModel
            .query(on: app.db)
            .filter(\.$verifiedAt == nil)
            .filter(\.$repository.$id == tagRepository.requireID())
            .join(parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
            .count()
        
        try app
            .describe("List unverified tags should return ok and unverified models for all languages")
            .get(tagPath.appending("\(tagRepository.requireID())/unverified/?per=\(tagCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Tag.Repository.ListUnverified>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedTagForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.detailId }.uniqued().count, unverifiedTagForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.detailId }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedTagForRepositoryCount)
                
                XCTAssert(content.items.contains { $0.detailId == createdUnverifiedDetail.id })
                if let unverifiedDetail = content.items.first(where: { $0.detailId == createdUnverifiedDetail.id }) {
                    XCTAssertEqual(unverifiedDetail.detailId, createdUnverifiedDetail.id)
                    XCTAssertEqual(unverifiedDetail.title, createdUnverifiedDetail.title)
                    XCTAssertEqual(unverifiedDetail.keywords, createdUnverifiedDetail.keywords)
                    XCTAssertEqual(unverifiedDetail.languageCode, createdUnverifiedDetail.language.languageCode)
                }
                
                XCTAssertFalse(content.items.contains { $0.detailId == verifiedDetail.id })
                
                XCTAssert(content.items.contains { $0.detailId == secondCreatedUnverifiedDetail.id })
                if let secondUnverifiedDetail = content.items.first(where: { $0.detailId == secondCreatedUnverifiedDetail.id }) {
                    XCTAssertEqual(secondUnverifiedDetail.detailId, secondCreatedUnverifiedDetail.id)
                    XCTAssertEqual(secondUnverifiedDetail.title, secondCreatedUnverifiedDetail.title)
                    XCTAssertEqual(secondUnverifiedDetail.keywords, secondCreatedUnverifiedDetail.keywords)
                    XCTAssertEqual(secondUnverifiedDetail.languageCode, secondCreatedUnverifiedDetail.language.languageCode)
                }
                
                XCTAssert(content.items.contains { $0.detailId == createdUnverifiedDetailInDifferentLanguage.id })
                if let unverifiedDetailInDifferentLanguage = content.items.first(where: { $0.detailId == createdUnverifiedDetailInDifferentLanguage.id }) {
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.detailId, createdUnverifiedDetailInDifferentLanguage.id)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.title, createdUnverifiedDetailInDifferentLanguage.title)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.keywords, createdUnverifiedDetailInDifferentLanguage.keywords)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.languageCode, createdUnverifiedDetailInDifferentLanguage.language.languageCode)
                }
                
                XCTAssertFalse(content.items.contains { $0.detailId == unverifiedDetailForDifferentRepository.id })
                XCTAssertFalse(content.items.contains { $0.detailId == unverifiedDetailForDeactivatedLanguage.id })
            }
            .test()
    }
    
    func testListUnverifiedDetailsForRepositoryAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        // Create an unverified tag
        let (tagRepository, _) = try await createNewTag()
        
        try app
            .describe("List unverified tag as user should fail")
            .get(tagPath.appending("\(tagRepository.requireID())/unverified/"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedDetailsForRepositoryWithoutTokenFails() async throws {
        // Create an unverified tag
        let (tagRepository, _) = try await createNewTag()
        
        try app
            .describe("List unverified tag without token should fail")
            .get(tagPath.appending("\(tagRepository.requireID())/unverified/"))
            .expect(.unauthorized)
            .test()
    }
}
