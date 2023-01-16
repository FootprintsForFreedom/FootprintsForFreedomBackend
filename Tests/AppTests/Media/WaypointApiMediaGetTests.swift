//
//  WaypointApiMediaGetTests.swift
//  
//
//  Created by niklhut on 15.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiMediaGetTests: AppTestCase, MediaTest {
    func testSuccessfulListVerifiedWaypointMediasWithPreferredLanguageReturnsVerifiedModelsForAllLanguagesButPrefersSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        let (waypointRepository, _, _) = try await createNewWaypoint(verified: true)
        
        // Create an unverified media
        let (unverifiedMediaRepository, _, _) = try await createNewMedia(waypointId: waypointRepository.requireID(), languageId: language.requireID(), userId: userId)
        // Create a verified media
        print("0")
        let (verifiedMediaRepository, createdVerifiedMedia, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language.requireID(), userId: userId)
        try await createdVerifiedMedia.$language.load(on: app.db)
        print("1")
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
        print("2")
        // Create a repository that is only available in the other language
        let (verifiedMediaRepositoryInDifferentLanguage, createdVerifiedMediaInDifferentLanguage, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language2.requireID(), userId: userId)
        try await createdVerifiedMediaInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        print("3")
        let (verifiedMediaRepositoryWithMultipleLanguages, _, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language2.requireID(), userId: userId)
        // Create a second model in the other language
        print("3")
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
        print("5")
        
        // Get verified media count
        let mediaCount = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List media with perferred language should return ok and verified models for all languages. However, it should prefer the specified language")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/media/?preferredLanguage=\(language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                XCTAssertEqual(content.items.map { $0.id }.uniqued().count, content.items.count)
                
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
    
    func testSuccessfulListVerifiedWaypointMediasWithoutPreferredLanguageReturnsVerifiedModlesForAllLanguagesAccordingToTheirPriority() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        let (waypointRepository, _, _) = try await createNewWaypoint(verified: true)
        
        // Create an unverified media
        let (unverifiedMediaRepository, _, _) = try await createNewMedia(languageId: language.requireID(), userId: userId)
        // Create a verified media
        let (verifiedMediaRepository, createdVerifiedMedia, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language.requireID(), userId: userId)
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
        let (verifiedMediaRepositoryInDifferentLanguage, createdVerifiedMediaInDifferentLanguage, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language2.requireID(), userId: userId)
        try await createdVerifiedMediaInDifferentLanguage.$language.load(on: app.db)
        // Create a repository that is available in both languages
        let (verifiedMediaRepositoryWithMultipleLanguages, _, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language2.requireID(), userId: userId)
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
        let mediaCount = try await MediaRepositoryModel
            .query(on: app.db)
            .with(\.$details) { $0.with(\.$language) }
            .count()
        
        try await Task.sleep(for: .seconds(1))
        
        try app
            .describe("List media should return ok")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/media/?per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssertEqual(content.metadata.total, content.items.count)
                
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
    
    func testSuccessfulListVerifiedWaypointMediasDoesNotReturnModelsForDeactivatedLanguages() async throws {
        let language = try await createLanguage()
        let deactivatedLanguage = try await createLanguage()
        
        let userId = try await getUser(role: .user).requireID()
        let (waypointRepository, _, _) = try await createNewWaypoint(verified: true)
        
        // Create a verified media
        let (verifiedMediaRepository, _, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: language.requireID(), userId: userId)
        
        // Create a media for a deactivated language
        let (verifiedMediaRepositoryForDeactivatedLanguage, _, _) = try await createNewMedia(verified: true, waypointId: waypointRepository.requireID(), languageId: deactivatedLanguage.requireID(), userId: userId)
        
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
            .get(waypointsPath.appending("\(waypointRepository.requireID())/media/?per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == verifiedMediaRepository.id })
                XCTAssertFalse(content.items.contains { $0.id == verifiedMediaRepositoryForDeactivatedLanguage.id })
            }
            .test()
    }
}
