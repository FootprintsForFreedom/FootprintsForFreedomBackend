//
//  StaticContentTest.swift
//  
//
//  Created by niklhut on 10.06.22.
//

@testable import App
import XCTVapor
import Fluent

protocol StaticContentTest: LanguageTest { }

extension StaticContentTest {
    var staticContentPath: String { "api/staticContent/" }
    
    func createNewStaticContent(
        repositoryTitle: String = "New title \(UUID())",
        requiredSnippets: [StaticContent.Snippet] = [],
        title: String = "New StaticContent title \(UUID())",
        text: String = "This is a text",
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: StaticContentRepositoryModel, detail: StaticContentDetailModel) {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let languageId: UUID = try await {
            if let languageId = languageId {
                return languageId
            } else {
                return try await createLanguage().requireID()
            }
        }()
        
        let repository = StaticContentRepositoryModel(slug: repositoryTitle.slugify(), requiredSnippets: requiredSnippets)
        try await repository.create(on: app.db)
        
        let detail = try await StaticContentDetailModel.createWith(
            title: title,
            text: text,
            languageId: languageId,
            repositoryId: repository.requireID(),
            userId: userId,
            on: app.db
        )
        
        return (repository, detail)
    }
}

extension StaticContentDetailModel {
    static func createWith(
        title: String,
        slug: String? = nil,
        text: String,
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let detail = self.init(
            title: title,
            slug: slug,
            text: text,
            languageId: languageId,
            repositoryId: repositoryId,
            userId: userId
        )
        try await detail.create(on: db)
        return detail
    }
}
