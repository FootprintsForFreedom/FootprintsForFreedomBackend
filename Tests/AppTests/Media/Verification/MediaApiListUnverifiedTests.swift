//
//  MediaApiListUnverifiedTests.swift
//  
//
//  Created by niklhut on 18.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiListUnverifiedTests: AppTestCase, MediaTest {
    func testSuccessfulListRepositoriesWithUnverifiedModels() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified media
        let (unverifiedMediaRepository, createdUnverifiedDetail, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        // Create a verified media
        let (verifiedMediaRepository, createdVerifiedDetail, createdVerifiedFile) = try await createNewMedia(status: .verified, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified media
        let _ = try await MediaDetailModel.createWith(
            status: .pending,
            title: "Not visible \(UUID())",
            detailText: "Some invisible detailText",
            source: "What is this?",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepository.requireID(),
            fileId: createdVerifiedFile.requireID(),
            userId: userId,
            on: app.db
        )
        // Create a media in the other language
        let (verifiedMediaRepositoryInDifferentLanguage, _, _) = try await createNewMedia(status: .verified, languageId: language2.requireID(), userId: userId)
        
        // Get unverified media count
        let media = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .with(\.$tags.$pivots)
            .all()
        
        let mediaCount = media.count
        
        let unverifiedMediaCount = media
            .filter { $0.details.contains { [Status.pending, .deleteRequested].contains($0.status) && $0.language.priority != nil } || $0.$tags.pivots.contains { [Status.pending, .deleteRequested].contains($0.status) } }
            .count
        
        try app
            .describe("List repositories with unverified models should return ok and the repositories")
            .get(mediaPath.appending("unverified/?preferredLanguage=\(language.languageCode)&per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedMediaCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, unverifiedMediaCount)
                XCTAssert(content.items.map { $0.id }.uniqued().count == content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedMediaCount)
                
                XCTAssert(content.items.contains { $0.id == unverifiedMediaRepository.id })
                if let unverifiedMedia = content.items.first(where: { $0.id == unverifiedMediaRepository.id }) {
                    XCTAssertEqual(unverifiedMedia.id, unverifiedMediaRepository.id)
                    XCTAssertEqual(unverifiedMedia.title, createdUnverifiedDetail.title)
                }
                
                
                // contains the verified media repository because it has a second unverified media model
                // here it should also return the verified model in the list for preview to see which media was edited
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                if let verifiedMedia = content.items.first(where: { $0.id == verifiedMediaRepository.id }) {
                    XCTAssertEqual(verifiedMedia.id, verifiedMediaRepository.id)
                    XCTAssertEqual(verifiedMedia.title, createdVerifiedDetail.title)
                }
                
                XCTAssertFalse(content.items.contains { $0.id == verifiedMediaRepositoryInDifferentLanguage.id })
            }
            .test()
    }
    
    func testListRepositoriesWithUnverifiedModelsAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        try app
            .describe("List repositories with unverified models as user should fail")
            .get(mediaPath.appending("unverified"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListRepositoriesWithUnverifiedModelsWithoutTokenFails() async throws {
        try app
            .describe("List repositories with unverified without token should fail")
            .get(mediaPath.appending("unverified"))
            .expect(.unauthorized)
            .test()
    }
    
    func testListUnverifiedDetailsForRepository() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified media
        let (mediaRepository, createdUnverifiedDetail, createdFile) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        try await createdUnverifiedDetail.$language.load(on: app.db)
        // Create a verified media for the same repository
        let verifiedDetail = try await MediaDetailModel.createWith(
            status: .verified,
            title: "Verified Media \(UUID())",
            detailText: "This is text",
            source: "What is this?",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: app.db
        )
        // Create a second not verified media for the same repository
        let secondCreatedUnverifiedDetail = try await MediaDetailModel.createWith(
            status: .pending,
            title: "Not visible \(UUID())",
            detailText: "Some invisible detailText",
            source: "What is that?",
            languageId: language.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: app.db
        )
        try await secondCreatedUnverifiedDetail.$language.load(on: app.db)
        // Create a second not verified media for the same repository in another language
        let createdUnverifiedDetailInDifferentLanguage = try await MediaDetailModel.createWith(
            status: .pending,
            title: "Different Language \(UUID())",
            detailText: "Not visible detailText, other language",
            source: "Hallo, was ist das?",
            languageId: language2.requireID(),
            repositoryId: mediaRepository.requireID(),
            fileId: createdFile.requireID(),
            userId: userId,
            on: app.db
        )
        try await createdUnverifiedDetailInDifferentLanguage.$language.load(on: app.db)
        // Create a not verified media for another repository
        let (_, unverifiedDetailForDifferentRepository, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)

        // Get unverified and verified media count
        let mediaCount = try await MediaDetailModel
            .query(on: app.db)
            .count()

        let unverifiedMediaForRepositoryCount = try await MediaDetailModel
            .query(on: app.db)
            .filter(\.$status ~~ [.pending, .deleteRequested])
            .filter(\.$repository.$id == mediaRepository.requireID())
            .count()

        try app
            .describe("List unverified medias should return ok and unverified models for all languages")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/?per=\(mediaCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Repository.ListUnverified>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, unverifiedMediaForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.modelId }.uniqued().count, unverifiedMediaForRepositoryCount)
                XCTAssertEqual(content.items.map { $0.modelId }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, unverifiedMediaForRepositoryCount)

                XCTAssert(content.items.contains { $0.modelId == createdUnverifiedDetail.id })
                if let unverifiedDetail = content.items.first(where: { $0.modelId == createdUnverifiedDetail.id }) {
                    XCTAssertEqual(unverifiedDetail.modelId, createdUnverifiedDetail.id)
                    XCTAssertEqual(unverifiedDetail.title, createdUnverifiedDetail.title)
                    XCTAssertEqual(unverifiedDetail.detailText, createdUnverifiedDetail.detailText)
                    XCTAssertEqual(unverifiedDetail.languageCode, createdUnverifiedDetail.language.languageCode)
                }

                XCTAssertFalse(content.items.contains { $0.modelId == verifiedDetail.id })

                XCTAssert(content.items.contains { $0.modelId == secondCreatedUnverifiedDetail.id })
                if let secondUnverifiedDetail = content.items.first(where: { $0.modelId == secondCreatedUnverifiedDetail.id }) {
                    XCTAssertEqual(secondUnverifiedDetail.modelId, secondCreatedUnverifiedDetail.id)
                    XCTAssertEqual(secondUnverifiedDetail.title, secondCreatedUnverifiedDetail.title)
                    XCTAssertEqual(secondUnverifiedDetail.detailText, secondCreatedUnverifiedDetail.detailText)
                    XCTAssertEqual(secondUnverifiedDetail.languageCode, secondCreatedUnverifiedDetail.language.languageCode)
                }

                XCTAssert(content.items.contains { $0.modelId == createdUnverifiedDetailInDifferentLanguage.id })
                if let unverifiedDetailInDifferentLanguage = content.items.first(where: { $0.modelId == createdUnverifiedDetailInDifferentLanguage.id }) {
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.modelId, createdUnverifiedDetailInDifferentLanguage.id)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.title, createdUnverifiedDetailInDifferentLanguage.title)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.detailText, createdUnverifiedDetailInDifferentLanguage.detailText)
                    XCTAssertEqual(unverifiedDetailInDifferentLanguage.languageCode, createdUnverifiedDetailInDifferentLanguage.language.languageCode)
                }

                XCTAssertFalse(content.items.contains { $0.modelId == unverifiedDetailForDifferentRepository.id })
            }
            .test()
    }
    
    func testListUnverifiedDetailsForRepositoryAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        // Create an unverified media
        let (mediaRepository, _, _) = try await createNewMedia()
        
        try app
            .describe("List unverified media as user should fail")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedDetailsForRepositoryWithoutTokenFails() async throws {
        // Create an unverified media
        let (mediaRepository, _, _) = try await createNewMedia()
        
        try app
            .describe("List unverified media without token should fail")
            .get(mediaPath.appending("\(mediaRepository.requireID())/unverified/"))
            .expect(.unauthorized)
            .test()
    }
}