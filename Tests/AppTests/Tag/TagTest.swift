//
//  TagTest.swift
//  
//
//  Created by niklhut on 27.05.22.
//

@testable import App
import XCTVapor
import Fluent

protocol TagTest: LanguageTest { }

extension TagTest {
    var tagPath: String { "api/v1/tags/" }
    
    func createNewTag(
        title: String = "New Tag title \(UUID())",
        keywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) }, // array with 5 random numbers between 10 and 100
        status: Status = .pending,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: TagRepositoryModel, detail: TagDetailModel) {
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
        
        let repository = TagRepositoryModel()
        try await repository.create(on: app.db)
        
        let detail = try await TagDetailModel.createWith(
            status: status,
            title: title,
            keywords: keywords,
            languageId: languageId,
            repositoryId: repository.requireID(),
            userId: userId,
            on: app.db
        )
        
        return (repository, detail)
    }
}

extension TagDetailModel {
    static func createWith(
        status: Status,
        title: String,
        slug: String? = nil,
        keywords: [String],
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let detail = self.init(
            status: status,
            title: title,
            slug: slug,
            keywords: keywords,
            languageId: languageId,
            repositoryId: repositoryId,
            userId: userId
        )
        try await detail.create(on: db)
        return detail
    }
    
    @discardableResult
    func updateWith(
        status: Status = .pending,
        title: String = "Updated Tag Title \(UUID())",
        slug: String? = nil,
        keywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) }, // array with 5 random numbers between 10 and 100,
        languageId: UUID? = nil,
        userId: UUID? = nil,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let detail = Self.init(
            status: status,
            title: title,
            slug: slug,
            keywords: keywords,
            languageId: languageId ?? self.$language.id,
            repositoryId: self.$repository.id,
            userId: userId ?? self.$user.id!
        )
        try await detail.create(on: db)
        return detail
    }
}
