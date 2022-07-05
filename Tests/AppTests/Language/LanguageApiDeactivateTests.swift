//
//  LanguageApiDeactivateTests.swift
//  
//
//  Created by niklhut on 19.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class LanguageApiDeactivateTests: AppTestCase, LanguageTest {
    func testSuccessfulDeactivateLanguage() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage()
        
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect(Language.Detail.Detail.self) { content in
                XCTAssertEqual(content.languageCode, language.languageCode)
                XCTAssertEqual(content.name, language.name)
                XCTAssertEqual(content.isRTL, language.isRTL)
            }
            .test()
    }
    
    func testDeactivateDeactivatedLanguageFails() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage(activated: false)
        
        try app
            .describe("Deactivate already deactivated language as admin should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testDeactivateLanguageAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        let language = try await createLanguage()
        
        try app
            .describe("Deactivate language as moderator should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testDeactivateLanguageAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let language = try await createLanguage()
        
        try app
            .describe("Deactivate language as user should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testDeactivateLanguageWithoutTokenFails() async throws {
        let language = try await createLanguage()
        
        try app
            .describe("Deactivate language without token should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/deactivate"))
            .expect(.unauthorized)
            .test()
    }
}
