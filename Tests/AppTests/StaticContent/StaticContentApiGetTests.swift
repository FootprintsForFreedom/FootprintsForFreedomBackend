//
//  StaticContentApiGetTests.swift
//  
//
//  Created by niklhut on 10.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class StaticContentApiGetTests: AppTestCase, StaticContentTest {
    
    // MARK: - List
    
    func testSuccessfulListStaticContent() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let language = try await createLanguage()
        let language2 = try await createLanguage()
        XCTAssertLessThan(language.priority!, language2.priority!)
        
        let userId = try await getUser(role: .user).requireID()
        
        // create a static content
        let staticContentWithLanguage1and2 = try await createNewStaticContent(languageId: language.requireID(), userId: userId)
        try await staticContentWithLanguage1and2.detail.$language.load(on: app.db)
        // add a detail in a different language
        let _ = try await StaticContentDetailModel.createWith(
            moderationTitle: "Some moderation title \(UUID())",
            title: "Different language \(UUID())",
            text: "Some text",
            languageId: language2.requireID(),
            repositoryId: staticContentWithLanguage1and2.repository.requireID(),
            userId: userId,
            on: app.db
        )
        
        let staticContentWithLanguage2 = try await createNewStaticContent(languageId: language2.requireID(), userId: userId)
        try await staticContentWithLanguage1and2.detail.$language.load(on: app.db)
        
        let staticContentCount = try await StaticContentRepositoryModel
            .query(on: app.db)
            .count()
        
        try app
            .describe("List static content should reurn ok")
            .get(staticContentPath.appending("?per=\(staticContentCount)"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<StaticContent.Detail.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == staticContentWithLanguage1and2.repository.id! })
                if let staticContent = content.items.first(where: { $0.id == staticContentWithLanguage1and2.repository.id! }) {
                    XCTAssertEqual(staticContent.slug, staticContentWithLanguage1and2.repository.slug)
                }
                
                
                XCTAssert(content.items.contains { $0.id == staticContentWithLanguage2.repository.id! })
                if let staticContent = content.items.first(where: { $0.id == staticContentWithLanguage2.repository.id! }) {
                    XCTAssertEqual(staticContent.slug, staticContentWithLanguage2.repository.slug)
                }
            }
            .test()
    }
    
    func testSuccessfulListStaticContentDoesNotListStaticContentWithDeactivatedLanguage() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        let deactivatedLanguage = try await createLanguage()
        
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let userId = try await getUser(role: .user).requireID()
        
        // create a static content
        let staticContentWithDeactivatedLanguage = try await createNewStaticContent(languageId: deactivatedLanguage.requireID(), userId: userId)
        
        let staticContentCount = try await StaticContentRepositoryModel
            .query(on: app.db)
            .count()
        
        try app
            .describe("List static content should return ok but no repositories which only have a deactivated language")
            .get(staticContentPath.appending("?per=\(staticContentCount)"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(AppApi.Page<StaticContent.Detail.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == staticContentWithDeactivatedLanguage.repository.id! })
            }
            .test()
    }
    
    func testListStaticContentAsModeratorFails() async throws {
        let moderatorToken = try await getToken(for: .moderator, verified: true)
        
        try app
            .describe("List static content as moderator should fail")
            .get(staticContentPath)
            .bearerToken(moderatorToken)
            .expect(.forbidden)
            .test()
    }
    
    func testListStaticContentWithoutTokenFails() async throws {
        try app
            .describe("List static content without token should fail")
            .get(staticContentPath)
            .expect(.unauthorized)
            .test()
    }
    
    // MARK: - Get
    
    func testSuccessfulGetStaticContentById() async throws {
        let staticContent = try await createNewStaticContent(requiredSnippets: [.username])
        try await staticContent.detail.$language.load(on: app.db)
        
        try app
            .describe("Get static content by id should return ok")
            .get(staticContentPath.appending(staticContent.repository.requireID().uuidString))
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, staticContent.repository.id)
                XCTAssertEqual(content.title, staticContent.detail.title)
                XCTAssertEqual(content.text, staticContent.detail.text)
                XCTAssertEqual(content.languageCode, staticContent.detail.language.languageCode)
                XCTAssertNil(content.requiredSnippets)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testSuccessfulGetStaticContentByRepositorySlug() async throws {
        let staticContent = try await createNewStaticContent(requiredSnippets: [.username])
        try await staticContent.detail.$language.load(on: app.db)
        
        try app
            .describe("Get static content by slug should return ok")
            .get(staticContentPath.appending(staticContent.repository.slug))
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, staticContent.repository.id)
                XCTAssertEqual(content.title, staticContent.detail.title)
                XCTAssertEqual(content.text, staticContent.detail.text)
                XCTAssertEqual(content.languageCode, staticContent.detail.language.languageCode)
                XCTAssertNil(content.requiredSnippets)
                XCTAssertNotNil(content.detailId)
            }
            .test()
    }
    
    func testSuccessfulGetStaticContentByIdAsAdmin() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        
        let staticContent = try await createNewStaticContent(requiredSnippets: [.username])
        try await staticContent.detail.$language.load(on: app.db)
        
        try app
            .describe("Get static content by id should return ok")
            .get(staticContentPath.appending(staticContent.repository.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, staticContent.repository.id)
                XCTAssertEqual(content.title, staticContent.detail.title)
                XCTAssertEqual(content.text, staticContent.detail.text)
                XCTAssertEqual(content.languageCode, staticContent.detail.language.languageCode)
                XCTAssertNotNil(content.requiredSnippets)
                XCTAssertEqual(content.requiredSnippets, staticContent.repository.requiredSnippets)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, staticContent.detail.id!)
            }
            .test()
    }
    
    func testSuccessfulGetStaticContentByRepositorySlugAsAdmin() async throws {
        let adminToken = try await getToken(for: .admin, verified: true)
        
        let staticContent = try await createNewStaticContent(requiredSnippets: [.username])
        try await staticContent.detail.$language.load(on: app.db)
        
        try app
            .describe("Get static content by slug should return ok")
            .get(staticContentPath.appending(staticContent.repository.slug))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .expect(StaticContent.Detail.Detail.self) { content in
                XCTAssertEqual(content.id, staticContent.repository.id)
                XCTAssertEqual(content.title, staticContent.detail.title)
                XCTAssertEqual(content.text, staticContent.detail.text)
                XCTAssertEqual(content.languageCode, staticContent.detail.language.languageCode)
                XCTAssertNotNil(content.requiredSnippets)
                XCTAssertEqual(content.requiredSnippets, staticContent.repository.requiredSnippets)
                XCTAssertNotNil(content.detailId)
                XCTAssertEqual(content.detailId, staticContent.detail.id!)
            }
            .test()
    }
    
    func testListStaticContentForDeactivatedLanguageFails() async throws {
        let adminToken = try await getToken(for: .admin)
        let deactivatedLanguage = try await createLanguage()
        
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(deactivatedLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let staticContent = try await createNewStaticContent(languageId: deactivatedLanguage.requireID())
        
        try app
            .describe("Get verified for deactivated language should fail")
            .get(staticContentPath.appending(staticContent.repository.requireID().uuidString))
            .bearerToken(adminToken)
            .expect(.notFound)
            .test()
    }
}
