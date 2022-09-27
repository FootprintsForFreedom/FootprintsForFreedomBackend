//
//  TagTest.swift
//  
//
//  Created by niklhut on 27.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

protocol TagTest: LanguageTest { }

extension TagTest {
    var tagPath: String { "api/v1/tags/" }
    
    func createNewTag(
        title: String = "New Tag title \(UUID())",
        keywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) }, // array with 5 random numbers between 10 and 100
        verified: Bool = false,
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
                return try await LanguageModel
                    .query(on: app.db)
                    .filter(\.$languageCode == "de")
                    .first()!
                    .requireID()
            }
        }()
        
        let repository = TagRepositoryModel()
        try await repository.create(on: app.db)
        
        let detail = try await TagDetailModel.createWith(
            verified: verified,
            title: title,
            keywords: keywords,
            languageId: languageId,
            repositoryId: repository.requireID(),
            userId: userId,
            on: self
        )
        
        return (repository, detail)
    }
}

extension TagDetailModel {
    static func createWith(
        verified: Bool,
        title: String,
        slug: String? = nil,
        keywords: [String],
        languageId: UUID,
        repositoryId: UUID,
        userId: UUID,
        on test: TagTest
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let detail = self.init(
            verifiedAt: nil,
            title: title,
            slug: slug,
            keywords: keywords,
            languageId: languageId,
            repositoryId: repositoryId,
            userId: userId
        )
        try await detail.create(on: test.app.db)
        
        if verified {
            try test.app
                .describe("Verify tag as moderator should be successful and return ok")
                .post(test.tagPath.appending("\(repositoryId)/verify/\(detail.requireID())"))
                .bearerToken(test.moderatorToken)
                .expect(.ok)
                .expect(.json)
                .expect(Tag.Detail.Detail.self) { content in
                    detail.slug = content.slug
                }
                .test()
        }
        
        return detail
    }
    
    @discardableResult
    func updateWith(
        verifiedAt: Date? = nil,
        title: String = "Updated Tag Title \(UUID())",
        slug: String? = nil,
        keywords: [String] = (1...5).map { _ in String(Int.random(in: 10...100)) }, // array with 5 random numbers between 10 and 100,
        languageId: UUID? = nil,
        userId: UUID? = nil,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let detail = Self.init(
            verifiedAt: verifiedAt,
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
