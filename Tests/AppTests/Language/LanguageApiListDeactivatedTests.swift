//
//  LanguageApiListDeactivatedTests.swift
//  
//
//  Created by niklhut on 19.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class LanguageApiListDeactivatedTests: AppTestCase, LanguageTest {
    func testSuccessfulListDeactivatedLanguages() async throws {
        let token = try await getToken(for: .admin)
        
        let language1 = try await createLanguage(activated: false)
        let language2 = try await createLanguage(activated: false)
        
        try app
            .describe("List deactivated languages as admin should return ok")
            .get(languagesPath.appending("deactivated"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect([Language.Detail.List].self) { content in
                XCTAssert(content.contains { $0.id == language1.id } )
                XCTAssert(content.contains { $0.id == language2.id } )
            }
            .test()
    }
    
    func testListDeactivatedLanguagesDoesNotReturnActivatedLanguages() async throws {
        let token = try await getToken(for: .admin)
        
        let activeLanguage = try await createLanguage()
        let deactivatedLanguage = try await createLanguage(activated: false)
        
        try app
            .describe("List deactivated languages should return active language")
            .get(languagesPath.appending("deactivated"))
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect([Language.Detail.List].self) { content in
                XCTAssert(content.contains { $0.id == deactivatedLanguage.id } )
                XCTAssertFalse(content.contains { $0.id == activeLanguage.id } )
            }
            .test()
    }
    
    func testListDeactivatedLanguagesAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        
        try app
            .describe("List deactivated languages as admin should return ok")
            .get(languagesPath.appending("deactivated"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testListDeactivatedLanguagesAsUserFails() async throws {
        let token = try await getToken(for: .user)
        
        try app
            .describe("List deactivated languages as admin should return ok")
            .get(languagesPath.appending("deactivated"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testListActivatedLanguagesWithoutTokenFails() async throws {
        try app
            .describe("List deactivated languages as admin should return ok")
            .get(languagesPath.appending("deactivated"))
            .expect(.unauthorized)
            .test()
    }
}
