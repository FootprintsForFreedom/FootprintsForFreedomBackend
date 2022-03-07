//
//  LanguageApiDeleteTests.swift
//  
//
//  Created by niklhut on 07.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class LanguageApiDeleteTests: AppTestCase {
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
    
    func testDeleteLanguageFails() async throws {
        let token = try await getToken(for: .superAdmin)
        let language = try await createLanguage()
        
        try app
            .describe("Delete language always fails succeeds")
            .delete(languagesPath.appending(language.requireID().uuidString))
            .bearerToken(token)
            .expect(.internalServerError)
            .test()
    }
}
