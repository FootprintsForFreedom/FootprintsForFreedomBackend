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

final class LanguageApiUpdateTests: AppTestCase, LanguageTest {
    private func getLanguageUpdateContent(
        languageCode: String = UUID().uuidString,
        name: String = UUID().uuidString,
        isRTL: Bool = false
    ) -> Language.Detail.Update {
        return .init(languageCode: languageCode, name: name, isRTL: isRTL)
    }
    
    func testSuccessfulUpdateLanguageAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let updatedLanguage = getLanguageUpdateContent()
        
        try app
            .describe("Update language should return ok and the created language")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Detail.Detail.self) { content in
                XCTAssertEqual(content.languageCode, updatedLanguage.languageCode)
                XCTAssertEqual(content.name, updatedLanguage.name)
                XCTAssertEqual(content.isRTL, updatedLanguage.isRTL)
            }
            .test()
    }
    
    func testUpdateLanguageAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
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
        let token = try await getToken(for: .user)
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
        let token = try await getToken(for: .admin)
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
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        let createdLanguage = LanguageModel(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false, priority: highestPriority + 1)
        try await createdLanguage.create(on: app.db)
        
        let updatedLanguage = getLanguageUpdateContent(languageCode: createdLanguage.languageCode)
        
        try app
            .describe("Update language with already present language code should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateLanguageNeedsValidName() async throws {
        let token = try await getToken(for: .admin)
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
    
    func testUpdateLanguageNeedsUniqueName() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        let createdLanguage = LanguageModel(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false, priority: highestPriority + 1)
        try await createdLanguage.create(on: app.db)
        let updatedLanguage = getLanguageUpdateContent(name: createdLanguage.name)
        
        try app
            .describe("Update language with already present name should fail")
            .put(languagesPath.appending(language.requireID().uuidString))
            .body(updatedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testUpdateLanguageNeedsIsRTL() async throws {
        let token = try await getToken(for: .admin)
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
