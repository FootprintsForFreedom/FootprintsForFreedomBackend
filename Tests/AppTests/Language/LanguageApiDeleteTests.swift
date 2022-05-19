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

final class LanguageApiDeleteTests: AppTestCase, LanguageTest {
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
