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
import ISO639

extension AppApi.Language.Detail.Create: Content { }

final class LanguageApiCreateTests: AppTestCase, LanguageTest {
    private func getLanguageCreateContent(
        languageCode: String? = nil
    ) async throws -> AppApi.Language.Detail.Create {
        let languageCode: String = try await {
            var languageCode = languageCode
            if languageCode == nil {
                try app
                    .describe("Moderator should be able to list unused languages.")
                    .get(languagesPath.appending("unused"))
                    .bearerToken(try await getToken(for: .admin))
                    .expect(.ok)
                    .expect(.json)
                    .expect([AppApi.Language.Detail.ListUnused].self) { content in
                        guard let randomLanguageCode = content.randomElement() else {
                            XCTFail()
                            return
                        }
                        languageCode = randomLanguageCode.languageCode
                    }
                    .test()
            }
            return languageCode!
        }()
        return .init(languageCode: languageCode)
    }
    
    func testSuccessfulCreateLanguageAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        for _ in 0...3 {
            let newLanguage = try await getLanguageCreateContent()
            
            // Get original languages count
            let languagesCount = try await LanguageModel.query(on: app.db).count()
            
            try app
                .describe("Create language should return ok and the created language")
                .post(languagesPath)
                .body(newLanguage)
                .bearerToken(token)
                .expect(.created)
                .expect(.json)
                .expect(AppApi.Language.Detail.Detail.self) { content in
                    XCTAssertEqual(content.languageCode, newLanguage.languageCode)
                    guard let language = ISO639.Language.from(with: content.languageCode) else {
                        XCTFail()
                        return
                    }
                    XCTAssertEqual(content.name, language.name)
                    XCTAssertEqual(content.officialName, language.official)
                    XCTAssertEqual(content.isRTL, ["ar", "arc", "dv", "fa", "ha", "he", "khw", "ks", "ku", "ps", "ur", "yi"].contains(content.languageCode))
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
        let newLanguage = try await getLanguageCreateContent()
        
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
        let newLanguage = try await getLanguageCreateContent()
        
        try app
            .describe("Create language as user should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testCreateLanguageWithoutTokenFails() async throws {
        let newLanguage = try await getLanguageCreateContent()
        
        try app
            .describe("Create language without token should fail")
            .post(languagesPath)
            .body(newLanguage)
            .expect(.unauthorized)
            .test()
    }
    
    func testCreateLanguageNeedsValidLanguageCode() async throws {
        let token = try await getToken(for: .admin)
        let newLanguage = try await getLanguageCreateContent(languageCode: "")
        
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
        let newLanguage = try await getLanguageCreateContent(languageCode: "de")
        
        try app
            .describe("Create language with already present language code should fail")
            .post(languagesPath)
            .body(newLanguage)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
}
