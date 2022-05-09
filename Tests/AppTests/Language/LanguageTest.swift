//
//  LanguageTest.swift
//  
//
//  Created by niklhut on 21.03.22.
//

@testable import App
import XCTVapor
import Fluent

protocol LanguageTest: AppTestCase { }

extension LanguageTest {
    func createLanguage(
        languageCode: String = UUID().uuidString,
        name: String = UUID().uuidString,
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
}
