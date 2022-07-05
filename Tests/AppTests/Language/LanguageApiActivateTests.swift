//
//  LanguageApiActivateTests.swift
//  
//
//  Created by niklhut on 19.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class LanguageApiActivateTests: AppTestCase, LanguageTest {
    func testSuccessfulActivateLanguage() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage(activated: false)
        
        try app
            .describe("Activate language as admin should return ok")
            .put(languagesPath.appending("\(language.requireID().uuidString)/activate"))
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
    
    func testActivateActivatedLanguageFails() async throws {
        let token = try await getToken(for: .admin)
        let language = try await createLanguage(activated: true)
        
        try app
            .describe("Activate already activated language as admin should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/activate"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testActivateLanguageAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        let language = try await createLanguage(activated: false)
        
        try app
            .describe("Activate language as moderator should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/activate"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testActivateLanguageAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let language = try await createLanguage(activated: false)
        
        try app
            .describe("Activate language as user should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/activate"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testActivateLanguageWithoutTokenFails() async throws {
        let language = try await createLanguage()
        
        try app
            .describe("Activate language without token should fail")
            .put(languagesPath.appending("\(language.requireID().uuidString)/activate"))
            .expect(.unauthorized)
            .test()
    }
}
