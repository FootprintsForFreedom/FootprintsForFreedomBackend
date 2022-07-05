//
//  LanguageApiCreateTests.swift
//  
//
//  Created by niklhut on 07.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Language.Detail.Create: Content { }

final class LanguageApiCreateTests: AppTestCase, LanguageTest {
    private func getLanguageCreateContent(
        languageCode: String = UUID().uuidString,
        name: String = UUID().uuidString,
        isRTL: Bool = false
    ) -> Language.Detail.Create {
        return .init(languageCode: languageCode, name: name, isRTL: isRTL)
    }
    
    func testSuccessfulCreateLanguageAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        for _ in 0...3 {
            let newLanguage = getLanguageCreateContent()
            
            // Get original languages count
            let languagesCount = try await LanguageModel.query(on: app.db).count()
            
            try app
                .describe("Create language should return ok and the created language")
                .post(languagesPath)
                .body(newLanguage)
                .bearerToken(token)
                .expect(.created)
                .expect(.json)
                .expect(Language.Detail.Detail.self) { content in
                    XCTAssertEqual(content.languageCode, newLanguage.languageCode)
                    XCTAssertEqual(content.name, newLanguage.name)
                    XCTAssertEqual(content.isRTL, newLanguage.isRTL)
                }
                .test()
            
            // New languages count should be one more than original languages count
            let newLanguagesCount = try await LanguageModel.query(on: app.db).count()
            XCTAssertEqual(newLanguagesCount, languagesCount + 1)
            
            // Check the priority has the highest value and is therefore the last important
            let languageWithLowestPriority = try await LanguageModel
                .query(on: app.db)
                .filter(\.$priority != nil)
                .sort(\.$priority, .descending) // Highest value first
                .first()
            XCTAssertEqual(languageWithLowestPriority?.languageCode, newLanguage.languageCode)
        }
    }
    
    func testCreateLanguageAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        let newLanguage = getLanguageCreateContent()
        
        try app
            .describe("Create language as moderator should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateLanguageAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let newLanguage = getLanguageCreateContent()
        
        try app
            .describe("Create language as user should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateLanguageWithoutTokenFails() async throws {
        let newLanguage = getLanguageCreateContent()
        
        try app
            .describe("Create language wihtout token should fail")
            .post(languagesPath)
            .body(newLanguage)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateLanguageNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .admin)
        let newLanguage = getLanguageCreateContent(languageCode: "")
        
        try app
            .describe("Create language with empty language code should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateLanguageNeedsUniqueLanguageCode() async throws  {
        let token = try await getToken(for: .admin)
        
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        let createdLanguage = LanguageModel(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false, priority: highestPriority + 1)
        try await createdLanguage.create(on: app.db)
        let newLanguage = getLanguageCreateContent(languageCode: "de")
        
        try app
            .describe("Create language with already present language code should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateLanguageNeedsValidName() async throws {
        let token = try await getToken(for: .admin)
        let newLanguage = getLanguageCreateContent(name: "")
        
        try app
            .describe("Create language with empty name should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateLanguageNeedsUniqueName() async throws {
        let token = try await getToken(for: .admin)
        
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        let createdLanguage = LanguageModel(languageCode: UUID().uuidString, name: UUID().uuidString, isRTL: false, priority: highestPriority + 1)
        try await createdLanguage.create(on: app.db)
        let newLanguage = getLanguageCreateContent(name: "Deutsch")
        
        try app
            .describe("Create language with already present name should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testCreateLanguageNeedsIsRTL() async throws {
        let token = try await getToken(for: .admin)
        struct Create: Content {
            public let languageCode: String
            public let name: String
        }
        let newLanguage = Create(languageCode: "en", name: "English")
        
        try app
            .describe("Create language with empty language code should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
