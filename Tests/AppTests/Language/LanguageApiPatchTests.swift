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

final class LanguageApiPatchTests: AppTestCase, LanguageTest {
    func testPatchLanguageFails() async throws {
        let token = try await getToken(for: .superAdmin)
        let language = try await createLanguage()
        
        try app
            .describe("Delete language always fails succeeds")
            .patch(languagesPath.appending(language.requireID().uuidString))
            .bearerToken(token)
            .expect(.internalServerError)
            .test()
    }
}
