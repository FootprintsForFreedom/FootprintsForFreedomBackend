//
//  TagApiDetailChangesTests.swift
//  
//
//  Created by niklhut on 29.05.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiDetailChangesTests: AppTestCase, TagTest {
    func testSuccessfulDetailChanges() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        let secondTagDetail = try await TagDetailModel.createWith(
            verified: false,
            title: "A different title \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: repository.requireID(),
            userId: user.requireID(),
            on: self
        )
        try await detail.$user.load(on: app.db)
        try await secondTagDetail.$user.load(on: app.db)
        
        try app
            .describe("Detail changes as moderator schould be successful and return ok and the changes")
            .get(tagPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())&to=\(secondTagDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Tag.Repository.Changes.self) { content in
                XCTAssertEqual(content.fromUser?.id, detail.user?.id)
                XCTAssertEqual(content.toUser?.id, secondTagDetail.user?.id)
            }
            .test()
    }
    
    func testDetailChangesAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        let secondTagDetail = try await TagDetailModel.createWith(
            verified: false,
            title: "A different title \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: repository.requireID(),
            userId: user.requireID(),
            on: self
        )
        
        try app
            .describe("Detail changes as user schould fail")
            .get(tagPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())&to=\(secondTagDetail.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDetailChangesWithoutTokenFails() async throws {
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        let secondTagDetail = try await TagDetailModel.createWith(
            verified: false,
            title: "A different title \(UUID())",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: language.requireID(),
            repositoryId: repository.requireID(),
            userId: user.requireID(),
            on: self
        )
        
        try app
            .describe("Detail changes without token should fail")
            .get(tagPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())&to=\(secondTagDetail.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDetailChangesMustContainFromId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        
        try app
            .describe("Detail changes request must contain from id field")
            .get(tagPath.appending("\(repository.requireID())/changes/?to=\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesMustContainToId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        
        try app
            .describe("Detail changes request must contain to id field")
            .get(tagPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesFromMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        let (_, secondTagDetail) = try await createNewTag(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when from model is form other repository")
            .get(tagPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())&to=\(secondTagDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesToMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language = try await createLanguage()
        let (_, detail) = try await createNewTag(languageId: language.requireID())
        let (secondRepository, secondTagDetail) = try await createNewTag(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when to model is from other repository")
            .get(tagPath.appending("\(secondRepository.requireID())/changes/?from=\(detail.requireID())&to=\(secondTagDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesWithModelsFromDifferentLanguageFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language = try await createLanguage()
        let secondLanguage = try await createLanguage()
        let (repository, detail) = try await createNewTag(languageId: language.requireID())
        let secondTagDetail = try await TagDetailModel.createWith(
            verified: false,
            title: "A different title",
            keywords: (1...5).map { _ in String(Int.random(in: 10...100)) },
            languageId: secondLanguage.requireID(),
            repositoryId: repository.requireID(),
            userId: user.requireID(),
            on: self
        )
        try await detail.$user.load(on: app.db)
        try await secondTagDetail.$user.load(on: app.db)
        
        try app
            .describe("Detail changes as moderator schould be successful and return ok and the changes")
            .get(tagPath.appending("\(repository.requireID())/changes/?from=\(detail.requireID())&to=\(secondTagDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
