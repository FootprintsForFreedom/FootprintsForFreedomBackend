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
    var languagesPath: String { "api/v1/languages/" }
    
    func createLanguage(
        languageCode: String? = nil,
        activated: Bool = true
    ) async throws -> LanguageModel {
        let adminToken = try await getToken(for: .admin)
        
        let languageCode: String = try {
            var languageCode = languageCode
            if languageCode == nil {
                try app
                    .describe("Moderator should be able to list unused languages.")
                    .get(languagesPath.appending("unused"))
                    .bearerToken(adminToken)
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
        
        var languageId: UUID?
        try app
            .describe("Create language should return ok and the created language")
            .post(languagesPath)
            .body(Language.Detail.Create(languageCode: languageCode))
            .bearerToken(adminToken)
            .expect(.created)
            .expect(.json)
            .expect(Language.Detail.Detail.self) { content in
                languageId = content.id
            }
            .test()
        
        if let languageId, !activated {
            try app
                .describe("Deactivate language as admin should return ok")
                .put(languagesPath.appending("\(languageId)/deactivate"))
                .bearerToken(adminToken)
                .expect(.ok)
                .expect(.json)
                .test()
        }
        
        let language = try await LanguageModel.query(on: app.db).filter(\.$languageCode == languageCode).first()!
        return language
    }
}
