//
//  LanguageApiPatchTests.swift
//  
//
//  Created by niklhut on 07.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Language.Language.Patch: Content { }

final class LanguageApiPatchTests: AppTestCase {
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
    
    private func getLanguagePatchContent(
        languageCode: String? = nil,
        name: String? = nil,
        isRTL: Bool? = nil
    ) -> Language.Language.Patch {
        return .init(languageCode: languageCode, name: name, isRTL: isRTL)
    }
    
    func testSuccessfulPatchLanguageCodeAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(languageCode: "en")
        
        try app
            .describe("Patch language code should return ok and the created language")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Language.Detail.self) { content in
                XCTAssertEqual(content.languageCode, patchedLanguage.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }
    
    func testSuccessfulPatchLanguageNameAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(name: "English")
        
        try app
            .describe("Patch language name should return ok and the created language")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Language.Detail.self) { content in
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, patchedLanguage.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }
    
    func testSuccessfulPatchLanguageRTLAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(isRTL: true)
        
        try app
            .describe("Patch language is RTL should return ok and the created language")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Language.Detail.self) { content in
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, patchedLanguage.isRTL)
            }
            .test()
    }
    
    func testEmptyPatchFails() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent()
        
        try app
            .describe("Empty patch language should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchLanguageAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(name: "English")

        try app
            .describe("Patch language as moderator should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchLanguageAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(name: "English")

        try app
            .describe("Patch language as user should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testPatchLanguageWithoutTokenFails() async throws {
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(name: "English")

        try app
            .describe("Patch language without token should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .expect(.unauthorized)
            .test()
    }
        
    func testPatchLanguageNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(languageCode: "")
        
        try app
            .describe("Patch language with empty language code should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchLanguageNeedsUniqueLanguageCode() async throws  {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        let createdLanguage = LanguageModel(languageCode: "en", name: "English", isRTL: false, priority: highestPriority + 1)
        try await createdLanguage.create(on: app.db)
        
        let patchedLanguage = getLanguagePatchContent(languageCode: "en")
        
        try app
            .describe("Patch language with already present language code should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchLanguageNeedsValidName() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        let patchedLanguage = getLanguagePatchContent(name: "")
        
        try app
            .describe("Patch language with empty name should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testPatchLanguageNeedsUniqueName() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        let createdLanguage = LanguageModel(languageCode: "en", name: "English", isRTL: false, priority: highestPriority + 1)
        try await createdLanguage.create(on: app.db)
        let patchedLanguage = getLanguagePatchContent(name: "English")
        
        try app
            .describe("Create language with already present name should fail")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .body(patchedLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
