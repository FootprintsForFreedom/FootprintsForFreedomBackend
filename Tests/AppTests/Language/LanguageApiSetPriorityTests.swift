//
//  LanguageApiSetPriorityTests.swift
//  
//
//  Created by niklhut on 19.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension Language.Detail.UpdatePriorities: Content { }

final class LanguageApiSetPriorityTests: AppTestCase, LanguageTest {    
    func testSuccessfulSetLanguagePriorities() async throws {
        let token = try await getToken(for: .admin)
        for _ in 1...4 { _ = try await createLanguage() }
        let activeLanguageIds = try await LanguageModel.query(on: app.db)
            .filter(\.$priority != nil)
            .field(\.$id)
            .all()
            .map { try $0.requireID() }
        
        let setLanguagesPriorityContent = Language.Detail.UpdatePriorities(newLanguagesOrder: activeLanguageIds.shuffled())
        
        try app
            .describe("Update language priorities as admin should return ok and the new order")
            .put(languagesPath.appending("priorities"))
            .body(setLanguagesPriorityContent)
            .bearerToken(token)
            .expect(.ok)
            .expect(.json)
            .expect([Language.Detail.List].self) { content in
                for languageId in activeLanguageIds {
                    XCTAssert(content.contains { $0.id == languageId })
                }
                // test the languages are returned in the correct, new order
                XCTAssertEqual(content.map { $0.id }, setLanguagesPriorityContent.newLanguagesOrder)
            }
            .test()
    }
    
    func testSetLanguagePrioritiesNeedsAllLanguageIdsInNewOrder() async throws {
        let token = try await getToken(for: .admin)
        
        let activeLanguageIds = try await (1...4).asyncMap { _ in try await self.createLanguage().requireID() }
        let _ = try await createLanguage()
        
        let setLanguagesPriorityContent = Language.Detail.UpdatePriorities(newLanguagesOrder: activeLanguageIds.shuffled())
        
        try app
            .describe("Update language priorities without all languages in the new order should fail")
            .put(languagesPath.appending("priorities"))
            .body(setLanguagesPriorityContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testSetLanguagePrioritiesWithDeactivatedLanguageInNewOrderFails() async throws {
        let token = try await getToken(for: .admin)
        
        let activeLanguageIds = try await (1...4).asyncMap { _ in try await self.createLanguage().requireID() }
        let deactivatedLanguageId = try await createLanguage(activated: false).requireID()
        
        var newLanguagesOrder = activeLanguageIds.shuffled()
        newLanguagesOrder.append(deactivatedLanguageId)
        
        let setLanguagesPriorityContent = Language.Detail.UpdatePriorities(newLanguagesOrder: newLanguagesOrder)
        
        try app
            .describe("Update language priorities with deactivated language in new order should fail")
            .put(languagesPath.appending("priorities"))
            .body(setLanguagesPriorityContent)
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testSetLanguagePrioritiesWithoutNewLanguagesOrderFails() async throws {
        let token = try await getToken(for: .admin)
        
        try app
            .describe("Update language priorities without new languages order should fail")
            .put(languagesPath.appending("priorities"))
            .bearerToken(token)
            .expect(.badRequest)
            .test()
    }
    
    func testSetLanguagePrioritiesAsModeratorFails() async throws {
        let token = try await getToken(for: .moderator)
        
        try app
            .describe("Update language priorities as moderator should fail")
            .put(languagesPath.appending("priorities"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testSetLanguagePrioritiesAsUserFails() async throws {
        let token = try await getToken(for: .user)
        
        try app
            .describe("Update language priorities as user should fail")
            .put(languagesPath.appending("priorities"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testSetLanguagePrioritiesWithoutTokenFails() async throws {
        try app
            .describe("Update language priorities wihtout token should fail")
            .put(languagesPath.appending("priorities"))
            .expect(.unauthorized)
            .test()
    }
}
