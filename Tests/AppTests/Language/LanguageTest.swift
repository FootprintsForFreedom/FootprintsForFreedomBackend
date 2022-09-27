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
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        let languageCode: String = try await {
            var languageCode = languageCode
            if languageCode == nil {
                try app
                    .describe("Moderator should be able to list unused languages.")
                    .get(languagesPath.appending("unused"))
                    .bearerToken(try await getToken(for: .admin))
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
        do {
            let language = try LanguageModel(languageCode: languageCode, priority: activated ? highestPriority + 1 : nil)
            try await language.create(on: app.db)
            return language
        } catch {
            print(languageCode)
            let existingLanguages = try await LanguageModel.query(on: app.db).all()
            dump(existingLanguages)
            fatalError()
        }
    }
}
