//
//  LanguageApiUpdateTests.swift
//  
//
//  Created by niklhut on 07.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Language.Language.Update: Content { }

final class LanguageApiUpdateTests: AppTestCase {
    let languagesPath = "api/languages/"
    
    private func createLanguage(
        languageCode: String = "\(UUID().uuidString)",
        name: String = "\(UUID().uuidString)",
        isRTL: Bool = false
    ) async throws -> LanguageModel {
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        let language = LanguageModel(languageCode: languageCode, name: name, isRTL: isRTL, priority: highestPriority + 1)
        try await language.create(on: app.db)
        return language
    }
    
    private func getLanguageUpdateContent(
        languageCode: String = "\(UUID().uuidString)",
        name: String = "\(UUID().uuidString)",
        isRTL: Bool = false
    ) -> Language.Language.Update {
        return .init(languageCode: languageCode, name: name, isRTL: isRTL)
    }
    
    func testSuccessfulUpdateLanguageAsAdmin() async throws {
        let token = try await getTokenFromOtherUser(role: .admin)
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent()
        
        try app
            .describe("Update language should return ok and the created language")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Language.Detail.self) { content in
                XCTAssertEqual(content.languageCode, updatedLanguage.languageCode)
                XCTAssertEqual(content.name, updatedLanguage.name)
                XCTAssertEqual(content.isRTL, updatedLanguage.isRTL)
            }
            .test()
    }
    
    func testUpdateLanguageAsModeratorFails() async throws {
        let token = try await getTokenFromOtherUser(role: .moderator)
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent()
        
        try app
            .describe("Update language as moderator should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateLanguageAsUserFails() async throws {
        let token = try await getTokenFromOtherUser(role: .user)
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent()
        
        try app
            .describe("Update language as user should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testUpdateLanguageWithoutTokenFails() async throws {
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent()
        
        try app
            .describe("Update language without token should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .expect(.unauthorized)
            .test()
    }
    
    func testUpdateLanguageNeedsValidLanguageCode() async throws {
        let token = try await getTokenFromOtherUser(role: .admin)
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent(languageCode: "")
        
        try app
            .describe("Update language with empty language code should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateLanguageNeedsUniqueLanguageCode() async throws  {
        let token = try await getTokenFromOtherUser(role: .admin)
        let language = try await createLanguage()
        
        let createdLanguage = LanguageModel(languageCode: "en", name: "English", isRTL: false, priority: 2)
        try await createdLanguage.create(on: app.db)
        
        let updatedLanguage = getLanguageUpdateContent(languageCode: "en")
        
        try app
            .describe("Update language with already present language code should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateLanguageNeedsValidName() async throws {
        let token = try await getTokenFromOtherUser(role: .admin)
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent(name: "")
        
        try app
            .describe("Update language with empty name should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateLanguageNeedsIsRTL() async throws {
        let token = try await getTokenFromOtherUser(role: .admin)
        let language = try await createLanguage()
        struct Update: Content {
            public let languageCode: String
            public let name: String
        }
        let updatedLanguage = Update(languageCode: "en", name: "English")
        
        try app
            .describe("Update language with empty language code should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
