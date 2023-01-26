//
//  MediaApiGetTests.swift
//  
//
//  Created by niklhut on 15.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiGetTests: AppTestCase, MediaTest {
    func testSuccessfulListVerifiedMediasWithPreferredLanguageReturnsVerifiedModelsForAllLanguagesButPrefersSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified media
        let (unverifiedMediaRepository, _, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        // Create a verified media
        let (verifiedMediaRepository, createdVerifiedMedia, _) = try await createNewMedia(verified: true, languageId: language.requireID(), userId: userId)
        try await createdVerifiedMedia.$language.load(on: app.db)
        // Create a second not verified model for the verified media that should not be returned
        let _ = try await MediaDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            detailText: "Not visible",
            source: "Any source",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepository.requireID(),
            fileId: createdVerifiedMedia.$media.id,
            userId: userId,
            on: self
        )
        // Create a repository that is only available in the other language
        let (verifiedMediaRepositoryInDifferentLanguage, createdVerifiedMediaInDifferentLanguage, _) = try await createNewMedia(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedMediaInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedMediaRepositoryWithMultipleLanguages, _, _) = try await createNewMedia(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedMediaInLanguage1 = try await MediaDetailModel.createWith(
            verified: true,
            title: "Language 2 \(UUID())",
            detailText: "Second detailText",
            source: "Some source",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepositoryWithMultipleLanguages.requireID(),
            fileId: createdVerifiedMedia.$media.id,
            userId: userId,
            on: self
        )
        try await createdVerifiedMediaInLanguage1.$language.load(on: app.db)
        
        // Get verified media count
        let media = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .all()
        
        let mediaCount = media.count
        
        let verifiedMediaCount = media
            .filter { $0.details.contains { $0.verifiedAt != nil && $0.language.priority != nil } }
            .count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List media with perferred language should return ok and verified models for all languages. However, it should prefer the specified language")
            .get(mediaPath.appending("?preferredLanguage=\(language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.count, verifiedMediaCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, verifiedMediaCount)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, content.items.count)
                XCTAssertEqual(content.metadata.total, verifiedMediaCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                if let verifiedMedia = content.items.first(where: { $0.id == verifiedMediaRepository.id }) {
                    XCTAssertEqual(verifiedMedia.id, verifiedMediaRepository.id)
                    XCTAssertEqual(verifiedMedia.title, createdVerifiedMedia.title)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepositoryInDifferentLanguage.id })
                if let verifiedMediaInDifferentLanguage = content.items.first(where: { $0.id == verifiedMediaRepositoryInDifferentLanguage.id }) {
                    XCTAssertEqual(verifiedMediaInDifferentLanguage.id, verifiedMediaRepositoryInDifferentLanguage.id)
                    XCTAssertEqual(verifiedMediaInDifferentLanguage.title, createdVerifiedMediaInDifferentLanguage.title)
                }
                
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepositoryWithMultipleLanguages.id })
                if let verifiedMediaWithMultipleLanguages = content.items.first(where:  { $0.id == verifiedMediaRepositoryWithMultipleLanguages.id }) {
                    XCTAssertEqual(verifiedMediaWithMultipleLanguages.id, verifiedMediaRepositoryWithMultipleLanguages.id)
                    XCTAssertEqual(verifiedMediaWithMultipleLanguages.title, createdVerifiedMediaInLanguage1.title)
                }
                
                XCTAssert(!content.items.contains { $0.id == unverifiedMediaRepository.id })
            }
            .test()
    }
    
    func testSuccessfulListVerifiedMediasWithoutPreferredLanguageReturnsVerifiedModlesForAllLanguagesAccordingToTheirPriority() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create an unverified media
        let (unverifiedMediaRepository, _, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        // Create a verified media
        let (verifiedMediaRepository, createdVerifiedMedia, _) = try await createNewMedia(verified: true, languageId: language.requireID(), userId: userId)
        // Create a second not verified model for the verified media that should not be returned
        let _ = try await MediaDetailModel.createWith(
            verified: false,
            title: "Not visible \(UUID())",
            detailText: "Not visible",
            source: "Any source",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepository.requireID(),
            fileId: createdVerifiedMedia.$media.id,
            userId: userId,
            on: self
        )
        // Create a repository that is only available in the other language
        let (verifiedMediaRepositoryInDifferentLanguage, createdVerifiedMediaInDifferentLanguage, _) = try await createNewMedia(verified: true, languageId: language2.requireID(), userId: userId)
        try await createdVerifiedMediaInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedMediaRepositoryWithMultipleLanguages, _, _) = try await createNewMedia(verified: true, languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        let createdVerifiedMediaInLanguage1 = try await MediaDetailModel.createWith(
            verified: true,
            title: "Language 2 \(UUID())",
            detailText: "Second detailText",
            source: "Some source",
            languageId: language.requireID(),
            repositoryId: verifiedMediaRepositoryWithMultipleLanguages.requireID(),
            fileId: createdVerifiedMedia.$media.id,
            userId: userId,
            on: self
        )
        
        // Get verified media count
        let media = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .all()
        
        let mediaCount = media.count
        
        let verifiedMediaCount = media
            .filter { $0.details.contains { $0.verifiedAt != nil && $0.language.priority != nil } }
            .count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List media should return ok")
            .get(mediaPath.appending("?per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssertEqual(content.items.count, verifiedMediaCount)
                
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                let verifiedMedia = content.items.first { $0.id == verifiedMediaRepository.id }!
                XCTAssertEqual(verifiedMedia.id, verifiedMediaRepository.id)
                XCTAssertEqual(verifiedMedia.title, createdVerifiedMedia.title)
                
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepositoryInDifferentLanguage.id })
                let verifiedMediaInDifferentLanguage = content.items.first { $0.id == verifiedMediaRepositoryInDifferentLanguage.id }!
                XCTAssertEqual(verifiedMediaInDifferentLanguage.id, verifiedMediaRepositoryInDifferentLanguage.id)
                XCTAssertEqual(verifiedMediaInDifferentLanguage.title, createdVerifiedMediaInDifferentLanguage.title)
                
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepositoryWithMultipleLanguages.id })
                let verifiedMediaWithMultipleLanguages = content.items.first { $0.id == verifiedMediaRepositoryWithMultipleLanguages.id }!
                XCTAssertEqual(verifiedMediaWithMultipleLanguages.id, verifiedMediaRepositoryWithMultipleLanguages.id)
                XCTAssertEqual(verifiedMediaWithMultipleLanguages.title, createdVerifiedMediaInLanguage1.title)
                
                XCTAssert(!content.items.contains { $0.id == unverifiedMediaRepository.id })
            }
            .test()
    }
    
    func testSuccessfulListVerifiedMediasDoesNotReturnModelsForDeactivatedLanguages() async throws {
        let language = try await createLanguage()
        let deactivatedLanguage = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        
        // Create a verified media
        let (verifiedMediaRepository, _, _) = try await createNewMedia(verified: true, languageId: language.requireID(), userId: userId)
        
        // Create a media for a deactivated language
        let (verifiedMediaRepositoryForDeactivatedLanguage, _, _) = try await createNewMedia(verified: true, languageId: deactivatedLanguage.requireID(), userId: userId)
        
        let adminToken = try await getToken(for: .admin)
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        // Get media count
        let media = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details)
            .all()
        
        let mediaCount = media.count
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List media should return ok")
            .get(mediaPath.appending("?per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                XCTAssertFalse(content.items.contains { $0.id == verifiedMediaRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }
    
    // TODO: if unverified, require user to be creator or moderator
    // but there is no crator?!
    func testSuccessfulGetVerifiedMedia() async throws {
        let language = try await createLanguage()
        let (mediaRepository, media, file) = try await createNewMedia(verified: true, languageId: language.requireID())
        try await media.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified media should return ok")
            .get(mediaPath.appending(mediaRepository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, mediaRepository.id)
                XCTAssertEqual(content.title, media.title)
                XCTAssertEqual(content.slug, media.slug)
                XCTAssertEqual(content.detailText, media.detailText)
                XCTAssertEqual(content.languageCode, media.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedMediaAsModerator() async throws {
        let language = try await createLanguage()
        let (mediaRepository, media, file) = try await createNewMedia(verified: true, languageId: language.requireID())
        try await media.$language.load(on: app.db)
        
        let moderatorToken = try await getToken(for: .moderator)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified media as moderator should return ok and more details")
            .get(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, mediaRepository.id)
                XCTAssertEqual(content.title, media.title)
                XCTAssertEqual(content.detailText, media.detailText)
                XCTAssertEqual(content.languageCode, media.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, media.id!)
            }
            .test()
    }
    
    func testSuccessfulGetVerifiedMediaBySlug() async throws {
        let language = try await createLanguage()
        let (mediaRepository, media, file) = try await createNewMedia(verified: true, languageId: language.requireID())
        try await media.$language.load(on: app.db)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get verified media by slug should return ok")
            .get(mediaPath.appending("find/\(media.slug)"))
            .expect(.ok)
            .expect(.json)
            .expect(Media.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, mediaRepository.id)
                XCTAssertEqual(content.title, media.title)
                XCTAssertEqual(content.slug, media.slug)
                XCTAssertEqual(content.detailText, media.detailText)
                XCTAssertEqual(content.languageCode, media.language.languageCode)
                XCTAssertEqual(content.group, file.group)
                XCTAssertEqual(content.filePath, file.relativeMediaFilePath)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testGetMediaForDeactivatedLanguageFails() async throws {
        let deactivatedLanguage = try await createLanguage()
        deactivatedLanguage.priority = nil
        
        let (mediaRepositoryForDeactivatedLanguage, _, _) = try await createNewMedia(verified: true, languageId: deactivatedLanguage.requireID())
        
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
            .describe("Get media for deactivated language should always fail; instead request the model directly")
            .get(mediaPath.appending(mediaRepositoryForDeactivatedLanguage.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }
    
    func testGetUnverifiedMediaFails() async throws {
        let (mediaRepository, _, _) = try await createNewMedia(verified: false)
        let userToken = try await getToken(for: .user)
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("Get unverified media should return not found")
            .get(mediaPath.appending(mediaRepository.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.notFound)
            .test()
    }
}
