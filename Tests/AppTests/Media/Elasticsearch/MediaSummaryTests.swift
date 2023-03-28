//
//  MediaSummaryTests.swift
//  
//
//  Created by niklhut on 16.01.23.
//

@testable import App
import XCTVapor
import Fluent
import Spec
import ElasticsearchNIOClient

final class MediaSummaryTests: AppTestCase, MediaTest, TagTest, UserTest {
    func testVerifyDetailAddsMediaToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode))
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.source, detail.source)
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.fileId, file.id)
        XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
        XCTAssertEqual(content.group, file.group)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testVerifyMediaTagUpdatesMediaInElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on media should return ok and the media with the tag")
            .post(mediaPath.appending("\(repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode))
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.source, detail.source)
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.fileId, file.id)
        XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
        XCTAssertEqual(content.group, file.group)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testVerifyDetailRemovesOlderVerifiedMediaFromElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, file) = try await createNewMedia()
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newDetail = try await detail.updateWith(on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        
        let elasticResponse = try await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newDetail.language.languageCode))
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, newDetail.title)
        XCTAssertEqual(content.slug, newDetail.title.slugify())
        XCTAssertEqual(content.source, newDetail.source)
        XCTAssertEqual(content.detailText, newDetail.detailText)
        XCTAssertEqual(content.languageId, newDetail.$language.id)
        XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(content.fileId, file.id)
        XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
        XCTAssertEqual(content.group, file.group)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testVerifyDetailInDifferentLanguageAddsMediaToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode))
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.source, detail.source)
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.fileId, file.id)
        XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
        XCTAssertEqual(content.group, file.group)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
        let secondElasticResponse = try await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newLanguage.languageCode))
        let secondContent = secondElasticResponse.source
        XCTAssertEqual(secondContent.id, repository.id)
        XCTAssertEqual(secondContent.title, newDetail.title)
        XCTAssertEqual(secondContent.slug, newDetail.title.slugify())
        XCTAssertEqual(secondContent.source, newDetail.source)
        XCTAssertEqual(secondContent.detailText, newDetail.detailText)
        XCTAssertEqual(secondContent.languageId, newDetail.$language.id)
        XCTAssertEqual(secondContent.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(secondContent.fileId, file.id)
        XCTAssertEqual(secondContent.relativeMediaFilePath, file.relativeMediaFilePath)
        XCTAssertEqual(secondContent.group, file.group)
        XCTAssert(try secondContent.tags.contains(tag.repository.requireID()))
    }
    
    func testDeleteRepositoryRemovesAllItsDetailsFromElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, _) = try await createNewMedia()
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let _ = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        
        try app
            .describe("A moderator should be able to delete an unverified media")
            .delete(mediaPath.appending(repository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        let elasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.wildcardSchema)
        XCTAssertNil(elasticResponse)
        let secondElasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.wildcardSchema)
        XCTAssertNil(secondElasticResponse)
    }
    
    func testDeactivateAndActivateLanguageRemovesAndAddsAllItsMediaFromAndToElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
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
        
        let elasticResponseAfterDeactivate = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode))
        XCTAssertNotNil(elasticResponseAfterDeactivate)
        let secondElasticResponseAfterDeactivate = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newDetail.language.languageCode))
        XCTAssertNil(secondElasticResponseAfterDeactivate)
        
        try app
            .describe("Activate language as admin should return ok")
            .put(languagesPath.appending("\(newLanguage.requireID().uuidString)/activate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        print(newLanguage.languageCode)
        
        let elasticResponseAfterActivate = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode))
        XCTAssertNotNil(elasticResponseAfterActivate)
        if let secondElasticResponseAfterActivate = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newDetail.language.languageCode)) {
            let content = secondElasticResponseAfterActivate.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, newDetail.title)
            XCTAssertEqual(content.slug, newDetail.title.slugify())
            XCTAssertEqual(content.source, newDetail.source)
            XCTAssertEqual(content.detailText, newDetail.detailText)
            XCTAssertEqual(content.languageId, newDetail.$language.id)
            XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
            XCTAssertEqual(content.fileId, file.id)
            XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(content.group, file.group)
            XCTAssert(try content.tags.contains(tag.repository.requireID()))
        } else {
            XCTFail()
        }
    }
    
    func testChangeLanguagePriorityChangesAllItsMediaLanguagePrioritiesInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$media.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
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
        
        if let elasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode)) {
            let content = elasticResponse.source
            XCTAssertEqual(content.languagePriority, setLanguagesPriorityContent.newLanguagesOrder.firstIndex(of: detail.$language.id)! + 1)
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, detail.title)
            XCTAssertEqual(content.slug, detail.title.slugify())
            XCTAssertEqual(content.source, detail.source)
            XCTAssertEqual(content.detailText, detail.detailText)
            XCTAssertEqual(content.languageId, detail.$language.id)
            XCTAssertEqual(content.languageCode, detail.language.languageCode)
            XCTAssertEqual(content.fileId, file.id)
            XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(content.group, file.group)
            XCTAssert(try content.tags.contains(tag.repository.requireID()))
        } else {
            XCTFail()
        }
        if  let secondElasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newDetail.language.languageCode)) {
            let secondContent = secondElasticResponse.source
            XCTAssertEqual(secondContent.id, repository.id)
            XCTAssertEqual(secondContent.title, newDetail.title)
            XCTAssertEqual(secondContent.slug, newDetail.title.slugify())
            XCTAssertEqual(secondContent.source, newDetail.source)
            XCTAssertEqual(secondContent.detailText, newDetail.detailText)
            XCTAssertEqual(secondContent.languageId, newDetail.$language.id)
            XCTAssertEqual(secondContent.languageCode, newDetail.language.languageCode)
            XCTAssertEqual(secondContent.fileId, file.id)
            XCTAssertEqual(secondContent.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(secondContent.group, file.group)
            XCTAssert(try secondContent.tags.contains(tag.repository.requireID()))
        } else {
            XCTFail()
        }
    }
    
    func testDeleteUserUpdatesAllTheirMediaDetailsInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, file) = try await createNewMedia()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let user = try await getUser(role: .user)
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), userId: user.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try await app
            .describe("User should be able to delete himself; Delete user should return ok")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(getToken(for: user))
            .expect(.noContent)
            .test()
        
        if let elasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode)) {
            let content = elasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, detail.title)
            XCTAssertEqual(content.slug, detail.title.slugify())
            XCTAssertEqual(content.source, detail.source)
            XCTAssertEqual(content.detailText, detail.detailText)
            XCTAssertEqual(content.languageId, detail.$language.id)
            XCTAssertEqual(content.languageCode, detail.language.languageCode)
            XCTAssertEqual(content.fileId, file.id)
            XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(content.group, file.group)
            XCTAssertEqual(content.detailUserId, detail.$user.id)
            XCTAssertEqual(content.fileUserId, file.$user.id)
        } else {
            XCTFail()
        }
        if let secondElasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newLanguage.languageCode)) {
            let content = secondElasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, newDetail.title)
            XCTAssertEqual(content.slug, newDetail.title.slugify())
            XCTAssertEqual(content.source, newDetail.source)
            XCTAssertEqual(content.detailText, newDetail.detailText)
            XCTAssertEqual(content.languageId, newDetail.$language.id)
            XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
            XCTAssertEqual(content.fileId, file.id)
            XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(content.group, file.group)
            XCTAssertNil(content.detailUserId)
            XCTAssertNotNil(content.fileUserId)
            XCTAssertEqual(content.fileUserId, file.$user.id)
        } else {
            XCTFail()
        }
    }
    
    func testDeleteUserUpdatesAllTheirMediaFilesInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let user = try await getUser(role: .user)
        let (repository, detail, file) = try await createNewMedia(userId: user.requireID())
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newUser = try await getUser(role: .user)
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), userId: newUser.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify media as moderator should be successful and return ok")
            .post(mediaPath.appending("\(repository.requireID())/verify/\(newDetail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try await app
            .describe("User should be able to delete himself; Delete user should return ok")
            .delete(usersPath.appending(user.requireID().uuidString))
            .bearerToken(getToken(for: user))
            .expect(.noContent)
            .test()
        
        if let elasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: detail.language.languageCode)) {
            let content = elasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, detail.title)
            XCTAssertEqual(content.slug, detail.title.slugify())
            XCTAssertEqual(content.source, detail.source)
            XCTAssertEqual(content.detailText, detail.detailText)
            XCTAssertEqual(content.languageId, detail.$language.id)
            XCTAssertEqual(content.languageCode, detail.language.languageCode)
            XCTAssertEqual(content.fileId, file.id)
            XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(content.group, file.group)
            XCTAssertNil(content.detailUserId)
            XCTAssertNil(content.fileUserId)
        } else {
            XCTFail()
        }
        if let secondElasticResponse = try? await app.elastic.get(document: MediaSummaryModel.Elasticsearch.self, id: repository.requireID().uuidString, from: MediaSummaryModel.Elasticsearch.schema(for: newLanguage.languageCode)) {
            let content = secondElasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, newDetail.title)
            XCTAssertEqual(content.slug, newDetail.title.slugify())
            XCTAssertEqual(content.source, newDetail.source)
            XCTAssertEqual(content.detailText, newDetail.detailText)
            XCTAssertEqual(content.languageId, newDetail.$language.id)
            XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
            XCTAssertEqual(content.fileId, file.id)
            XCTAssertEqual(content.relativeMediaFilePath, file.relativeMediaFilePath)
            XCTAssertEqual(content.group, file.group)
            XCTAssertNotNil(content.detailUserId)
            XCTAssertEqual(content.detailUserId, newDetail.$user.id)
            XCTAssertNil(content.fileUserId)
            
        } else {
            XCTFail()
        }
    }
}
