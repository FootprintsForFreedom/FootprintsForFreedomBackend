//
//  LatestVerifiedTagTests.swift
//  
//
//  Created by niklhut on 16.09.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec
import ElasticsearchNIOClient

final class LatestVerifiedTagTests: AppTestCase, TagTest {
    func testVerifyDetailAddsTagToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail) = try await createNewTag()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.keywords, detail.keywords)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
    }
    
    func testVerifyDetailRemovesOlderVerifiedTagsFromElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail) = try await createNewTag()
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newDetail = try await detail.updateWith(on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        
        let elasticResponse = try await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, newDetail.title)
        XCTAssertEqual(content.slug, newDetail.title.slugify())
        XCTAssertEqual(content.keywords, newDetail.keywords)
        XCTAssertEqual(content.languageId, newDetail.$language.id)
        XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(content.languagePriority, newDetail.language.priority)
    }
    
    func testVerifyDetailInDifferentLanguageAddsTagToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail) = try await createNewTag()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.keywords, detail.keywords)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.languagePriority, detail.language.priority)
        let secondElasticResponse = try await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        let secondContent = secondElasticResponse.source
        XCTAssertEqual(secondContent.id, repository.id)
        XCTAssertEqual(secondContent.title, newDetail.title)
        XCTAssertEqual(secondContent.slug, newDetail.title.slugify())
        XCTAssertEqual(secondContent.keywords, newDetail.keywords)
        XCTAssertEqual(secondContent.languageId, newDetail.$language.id)
        XCTAssertEqual(secondContent.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(secondContent.languagePriority, newDetail.language.priority)
    }
    
    func testDeleteRepositoryRemovesAllItsDetailsFromElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail) = try await createNewTag()
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("A moderator should be able to delete an unverified tag")
            .delete(tagPath.appending(repository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        let elasticResponse = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNil(elasticResponse)
        let secondElasticResponse = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNil(secondElasticResponse)
    }
    
    func testDeactivateAndActivateLanguageRemovesAndAddsAllItsTagsFromAndToElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail) = try await createNewTag()
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Deactivate language as admin should return ok")
            .put(languagesPath.appending("\(newLanguage.requireID().uuidString)/deactivate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponseAfterDeactivate = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNotNil(elasticResponseAfterDeactivate)
        let secondElasticResponseAfterDeactivate = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNil(secondElasticResponseAfterDeactivate)
        
        try app
            .describe("Activate language as admin should return ok")
            .put(languagesPath.appending("\(newLanguage.requireID().uuidString)/activate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponseAfterActivate = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNotNil(elasticResponseAfterActivate)
        let secondElasticResponseAfterActivate = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNotNil(secondElasticResponseAfterActivate)
    }
    
    func testChangeLanguagePriorityChangesAllItsTagsLanguagePrioritiesInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail) = try await createNewTag()
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        
        try app
            .describe("Verify tag as moderator should be successful and return ok")
            .post(tagPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
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
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNotNil(elasticResponse)
        XCTAssertEqual(elasticResponse?.source.languagePriority, setLanguagesPriorityContent.newLanguagesOrder.firstIndex(of: detail.$language.id)! + 1)
        let secondElasticResponse = try? await app.elastic.get(document: LatestVerifiedTagModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: LatestVerifiedTagModel.Elasticsearch.schema)
        XCTAssertNotNil(secondElasticResponse)
        XCTAssertEqual(secondElasticResponse?.source.languagePriority, try setLanguagesPriorityContent.newLanguagesOrder.firstIndex(of: newLanguage.requireID())! + 1)
    }
}
