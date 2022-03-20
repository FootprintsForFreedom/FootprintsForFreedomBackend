//
//  LanguageApiGetTests.swift
//  
//
//  Created by niklhut on 07.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class LanguageApiGetTests: AppTestCase {
    let languagesPath = "api/languages/"
    
    private func createLanguage(
        languageCode: String = UUID().uuidString,
        name: String = (UUID().uuidString),
        isRTL: Bool = false
    ) async throws -> LanguageModel {
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        let language = LanguageModel(languageCode: languageCode, name: name, isRTL: isRTL, priority: highestPriority + 1)
        try await language.create(on: app.db)
        return language
    }
    
    func testSuccessfulListLanguagesReturnsLanguagesByPriority() async throws {
        for _ in 0...4 {
            let language = try await createLanguage()
            
            // Get languages count
            let languagesCount = try await LanguageModel.query(on: app.db).filter(\.$priority != nil).count()
            
            try app
                .describe("List languages should return all languages sorted by their priority")
                .get(languagesPath)
                .expect(.ok)
                .expect(.json)
                .expect([Language.Language.List].self) { content in
                    XCTAssertEqual(languagesCount, content.count)
                    
                    XCTAssert(content.contains { $0.languageCode == language.languageCode })
                    XCTAssertEqual(content.last!.languageCode, language.languageCode)
                }
                .test()
        }
    }
    
    func testSuccessfulGetLanguage() async throws {
        let language = try await createLanguage()
        
        try app
            .describe("Get language should return the specified language")
            .get(languagesPath.appending(language.languageCode))
            .expect(.ok)
            .expect(.json)
            .expect(Language.Language.Detail.self) { content in
                XCTAssertEqual(content.id, language.id)
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }
    
    func testListLanguageDoesNotReturnDeactivatedLanguages() async throws {
        var languages = [LanguageModel]()
        for _ in 0...4 {
            let language = try await createLanguage()
            languages.append(language)
        }
        languages.last!.priority = nil
        try await languages.last!.update(on: app.db)
        
        // Get languages count
        let languagesCount = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .count()
        
        try app
            .describe("List languages should return all languages sorted by their priority except for the deactivated ones")
            .get(languagesPath)
            .expect(.ok)
            .expect(.json)
            .expect([Language.Language.List].self) { content in
                XCTAssertEqual(languagesCount, content.count)
                XCTAssert(!content.contains { $0.id == languages.last!.id })
            }
            .test()
    }
    
    func testSuccessfulGetDeactivatedLanguageAsAdmin() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        language.priority = nil
        try await language.update(on: app.db)
        
        try app
            .describe("Get language should return the specified language")
            .get(languagesPath.appending(language.languageCode))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Language.Detail.self) { content in
                XCTAssertEqual(content.id, language.id)
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }
    
    func testGetDeactivatedLanguageAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        let language = try await createLanguage()
        language.priority = nil
        try await language.update(on: app.db)
        
        try app
            .describe("Get deactivated language as moderator should fail")
            .get(languagesPath.appending(language.languageCode))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
}