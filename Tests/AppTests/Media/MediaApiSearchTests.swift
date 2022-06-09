//
//  MediaApiSearchTests.swift
//  
//
//  Created by niklhut on 05.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiSearchTests: AppTestCase, MediaTest, TagTest {
    func testSuccessfulSearchMediaReturnsWhenTextInTitle() async throws {
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should return the media if it is verified and has the search text in the title")
            .get(mediaPath.appending("search/?text=besonder&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
                guard let searchedMedia = content.items.first(where: { $0.id == media.repository.id }) else {
                    XCTFail("Could not find searched media")
                    return
                }
                XCTAssertEqual(searchedMedia.title, media.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchMediaReturnsWhenTextInDetailText() async throws {
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should return the media if it is verified and has the search text in the detail text")
            .get(mediaPath.appending("search/?text=ander&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
                guard let searchedMedia = content.items.first(where: { $0.id == media.repository.id }) else {
                    XCTFail("Could not find searched media")
                    return
                }
                XCTAssertEqual(searchedMedia.title, media.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchMediaOnlyReturnsVerifiedMedias() async throws {
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .pending)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should not return the media if it is unverified")
            .get(mediaPath.appending("search/?text=ander&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchMediaDoesNotReturnWhenTextNotInTitleOrDetailText() async throws {
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should not return the media if it is verified but does not have the search text in the title or detail text")
            .get(mediaPath.appending("search/?text=hallo&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchMediaReturnsWhenTextInTagTitle() async throws {
        let language = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], status: .verified, languageId: language.requireID())
        let media = try await createNewMedia(status: .verified, languageId: language.requireID())
        try await media.repository.$tags.attach(tag.repository, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should return the media if it is verified and has the search text in a connected tag title")
            .get(mediaPath.appending("search/?text=besonder&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
                guard let searchedMedia = content.items.first(where: { $0.id == media.repository.id }) else {
                    XCTFail("Could not find searched media")
                    return
                }
                XCTAssertEqual(searchedMedia.title, media.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchMediaReturnsWhenTextInTagKeywords() async throws {
        let language = try await createLanguage()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], status: .verified, languageId: language.requireID())
        let media = try await createNewMedia(status: .verified, languageId: language.requireID())
        try await media.repository.$tags.attach(tag.repository, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should return the media if it is verified and has the search text in a connected tag keyword")
            .get(mediaPath.appending("search/?text=ander&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
                guard let searchedMedia = content.items.first(where: { $0.id == media.repository.id }) else {
                    XCTFail("Could not find searched media")
                    return
                }
                XCTAssertEqual(searchedMedia.title, media.detail.title)
            }
            .test()
    }
    
    func testSuccessfulSearchOnlySearchesNewestVerifiedVersionOfTag() async throws {
        let language = try await createLanguage()
        let userId = try await getUser(role: .user).requireID()
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], status: .verified, languageId: language.requireID())
        let _ = try await TagDetailModel.createWith(
            status: .verified,
            title: "Das wird nicht gefunden",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: userId,
            on: app.db
        )
        
        let media = try await createNewMedia(status: .verified, languageId: language.requireID())
        try await media.repository.$tags.attach(tag.repository, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should only search the newest version of a connected tag")
            .get(mediaPath.appending("search/?text=er&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchOnlySearchesTagsInSpecifiedLangauge() async throws {
        let tag = try await createNewTag(title: "Ein besonderer Titel \(UUID())", keywords: ["Anders"], status: .verified)
        let media = try await createNewMedia(status: .verified)
        try await media.repository.$tags.attach(tag.repository, on: app.db)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should only serach tag details in the specified language")
            .get(mediaPath.appending("search/?text=er&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchMediaOnlyReturnsDetailsForSpecifiedLanguage() async throws {
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified, languageId: language.requireID())
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should only return medias for the specified language")
            .get(mediaPath.appending("search/?text=ander&languageCode=\(language2.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchMediaDoesNotReturnDetailsForDeactivatedLanguage() async throws {
        let language = try await createLanguage(activated: false)
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified, languageId: language.requireID())
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should only return medias for the specified language")
            .get(mediaPath.appending("search/?text=ander&languageCode=\(language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == media.repository.id })
            }
            .test()
    }
    
    func testSuccessfulSearchMediaOnlyReturnsNewestVerifiedDetailForRepository() async throws {
        let language = try await createLanguage()
        let userId = try await getUser(role: .user).requireID()
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified, languageId: language.requireID())
        let newerMedia = try await MediaDetailModel.createWith(
            status: .verified,
            title: "Ein besonderer Titel \(UUID()) neu",
            detailText: "Ein neuer anderer Text",
            source: "Quelle",
            languageId: language.requireID(),
            repositoryId: media.repository.requireID(),
            fileId: media.file.requireID(),
            userId: userId,
            on: app.db
        )
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should only return the newest verified detail for a media repository")
            .get(mediaPath.appending("search/?text=besonder&languageCode=\(language.languageCode)&per=\(mediaCount)"))
            .expect(.ok)
            .expect(.json)
            .expect(Page<Media.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == media.repository.id })
                guard let searchedMedia = content.items.first(where: { $0.id == media.repository.id }) else {
                    XCTFail("Could not find searched media")
                    return
                }
                XCTAssertEqual(searchedMedia.title, newerMedia.title)
                XCTAssertNotEqual(searchedMedia.title, media.detail.title)
                XCTAssert(!content.items.contains(where: { $0.title == media.detail.title }))
                XCTAssert(content.items.contains(where: { $0.title == newerMedia.title }))
            }
            .test()
    }
    
    func testSearchMediaNeedsValidText() async throws {
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should return the text query field is empty")
            .get(mediaPath.appending("search/?text=&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Search media should return the text query field is only a whitespace or a newline")
            .get(mediaPath.appending("search/?text=%20\n&languageCode=\(media.detail.language.languageCode)&per=\(mediaCount)"))
            .expect(.badRequest)
            .test()
    }
    
    func testSearchMediaNeedsValidLanguageCode() async throws {
        let media = try await createNewMedia(title: "Ein besonderer Titel \(UUID())", detailText: "Anderer Text", status: .verified)
        try await media.detail.$language.load(on: app.db)
        
        let mediaCount = try await MediaRepositoryModel.query(on: app.db).count()
        
        try app
            .describe("Search media should return the text query field is empty")
            .get(mediaPath.appending("search/?text=bes&per=\(mediaCount)"))
            .expect(.badRequest)
            .test()
    }

}