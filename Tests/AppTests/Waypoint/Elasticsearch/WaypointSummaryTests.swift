//
//  WaypointSummaryTests.swift
//  
//
//  Created by niklhut on 16.09.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec
import ElasticsearchNIOClient

final class WaypointSummaryTests: AppTestCase, WaypointTest, TagTest, UserTest {
    func testVerifyDetailAddsWaypointToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, location) = try await createNewWaypoint()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testVerifyLocationAddsOrUpdatesWaypointsToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, location) = try await createNewWaypoint()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()

        let elasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.languagePriority, detail.language.priority)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
        let secondElasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let secondContent = secondElasticResponse.source
        XCTAssertEqual(secondContent.id, repository.id)
        XCTAssertEqual(secondContent.title, newDetail.title)
        XCTAssertEqual(secondContent.slug, newDetail.title.slugify())
        XCTAssertEqual(secondContent.detailText, newDetail.detailText)
        XCTAssertEqual(secondContent.languageId, newDetail.$language.id)
        XCTAssertEqual(secondContent.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(secondContent.languagePriority, newDetail.language.priority)
        XCTAssertEqual(secondContent.location.lat, location.latitude)
        XCTAssertEqual(secondContent.location.lon, location.longitude)
        XCTAssert(try secondContent.tags.contains(tag.repository.requireID()))

        // Test update location

        let newLocation = try await location.updateWith(on: app.db)

        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(newLocation.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponseAfterUpdateLocation = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let contentAfterUpdateLocation = elasticResponseAfterUpdateLocation.source
        XCTAssertEqual(contentAfterUpdateLocation.id, repository.id)
        XCTAssertEqual(contentAfterUpdateLocation.title, detail.title)
        XCTAssertEqual(contentAfterUpdateLocation.slug, detail.title.slugify())
        XCTAssertEqual(contentAfterUpdateLocation.detailText, detail.detailText)
        XCTAssertEqual(contentAfterUpdateLocation.languageId, detail.$language.id)
        XCTAssertEqual(contentAfterUpdateLocation.languageCode, detail.language.languageCode)
        XCTAssertEqual(contentAfterUpdateLocation.languagePriority, detail.language.priority)
        XCTAssertEqual(contentAfterUpdateLocation.location.lat, newLocation.latitude)
        XCTAssertEqual(contentAfterUpdateLocation.location.lon, newLocation.longitude)
        XCTAssert(try contentAfterUpdateLocation.tags.contains(tag.repository.requireID()))
        let secondElasticResponseAfterUpdateLocation = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let secondContentAfterUpdateLocation = secondElasticResponseAfterUpdateLocation.source
        XCTAssertEqual(secondContentAfterUpdateLocation.id, repository.id)
        XCTAssertEqual(secondContentAfterUpdateLocation.title, newDetail.title)
        XCTAssertEqual(secondContentAfterUpdateLocation.slug, newDetail.title.slugify())
        XCTAssertEqual(secondContentAfterUpdateLocation.detailText, newDetail.detailText)
        XCTAssertEqual(secondContentAfterUpdateLocation.languageId, newDetail.$language.id)
        XCTAssertEqual(secondContentAfterUpdateLocation.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(secondContentAfterUpdateLocation.languagePriority, newDetail.language.priority)
        XCTAssertEqual(secondContentAfterUpdateLocation.location.lat, newLocation.latitude)
        XCTAssertEqual(secondContentAfterUpdateLocation.location.lon, newLocation.longitude)
        XCTAssert(try secondContentAfterUpdateLocation.tags.contains(tag.repository.requireID()))
    }
    
    // TODO: tags...
    
    func testVerifyWaypointTagUpdatesWaypointsInElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, location) = try await createNewWaypoint()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        
        try app
            .describe("Verify tag on waypoint should return ok and the waypoint with the tag")
            .post(waypointsPath.appending("\(repository.requireID())/tags/verify/\(tag.repository.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testVerifyDetailRemovesOlderVerifiedWaypointsFromElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, location) = try await createNewWaypoint()
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newDetail = try await detail.updateWith(on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        
        let elasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, newDetail.title)
        XCTAssertEqual(content.slug, newDetail.title.slugify())
        XCTAssertEqual(content.detailText, newDetail.detailText)
        XCTAssertEqual(content.languageId, newDetail.$language.id)
        XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(content.languagePriority, newDetail.language.priority)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testVerifyDetailInDifferentLanguageAddsWaypointToElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, location) = try await createNewWaypoint()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let content = elasticResponse.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.languagePriority, detail.language.priority)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
        let secondElasticResponse = try await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        let secondContent = secondElasticResponse.source
        XCTAssertEqual(secondContent.id, repository.id)
        XCTAssertEqual(secondContent.title, newDetail.title)
        XCTAssertEqual(secondContent.slug, newDetail.title.slugify())
        XCTAssertEqual(secondContent.detailText, newDetail.detailText)
        XCTAssertEqual(secondContent.languageId, newDetail.$language.id)
        XCTAssertEqual(secondContent.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(secondContent.languagePriority, newDetail.language.priority)
        XCTAssertEqual(secondContent.location.lat, location.latitude)
        XCTAssertEqual(secondContent.location.lon, location.longitude)
        XCTAssert(try secondContent.tags.contains(tag.repository.requireID()))
    }
    
    func testDeleteRepositoryRemovesAllItsDetailsFromElasticsearch() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (repository, detail, location) = try await createNewWaypoint()
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("A moderator should be able to delete an unverified waypoint")
            .delete(waypointsPath.appending(repository.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        let elasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNil(elasticResponse)
        let secondElasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNil(secondElasticResponse)
    }
    
    func testDeactivateAndActivateLanguageRemovesAndAddsAllItsWaypointsFromAndToElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, location) = try await createNewWaypoint()
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
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
        
        let elasticResponseAfterDeactivate = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNotNil(elasticResponseAfterDeactivate)
        let secondElasticResponseAfterDeactivate = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNil(secondElasticResponseAfterDeactivate)
        
        try app
            .describe("Activate language as admin should return ok")
            .put(languagesPath.appending("\(newLanguage.requireID().uuidString)/activate"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let elasticResponseAfterActivate = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNotNil(elasticResponseAfterActivate)
        let secondElasticResponseAfterActivate = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNotNil(secondElasticResponseAfterActivate)
        let content = secondElasticResponseAfterActivate!.source
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, newDetail.title)
        XCTAssertEqual(content.slug, newDetail.title.slugify())
        XCTAssertEqual(content.detailText, newDetail.detailText)
        XCTAssertEqual(content.languageId, newDetail.$language.id)
        XCTAssertEqual(content.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(content.languagePriority, newDetail.language.priority)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
    }
    
    func testChangeLanguagePriorityChangesAllItsWaypointsLanguagePrioritiesInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, location) = try await createNewWaypoint()
        try await detail.$language.load(on: app.db)
        
        let tag = try await createNewTag()
        try await repository.$tags.attach(tag.repository, method: .ifNotExists, on: app.db)
        let tagPivot = try await repository.$tags.$pivots.query(on: app.db)
            .filter(\.$waypoint.$id == repository.requireID())
            .filter(\.$tag.$id == tag.repository.requireID())
            .first()!
        tagPivot.status = .verified
        try await tagPivot.save(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        try await newDetail.$language.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
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
        
        let elasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNotNil(elasticResponse)
        let content = elasticResponse!.source
        XCTAssertEqual(content.languagePriority, setLanguagesPriorityContent.newLanguagesOrder.firstIndex(of: detail.$language.id)! + 1)
        XCTAssertEqual(content.id, repository.id)
        XCTAssertEqual(content.title, detail.title)
        XCTAssertEqual(content.slug, detail.title.slugify())
        XCTAssertEqual(content.detailText, detail.detailText)
        XCTAssertEqual(content.languageId, detail.$language.id)
        XCTAssertEqual(content.languageCode, detail.language.languageCode)
        XCTAssertEqual(content.location.lat, location.latitude)
        XCTAssertEqual(content.location.lon, location.longitude)
        XCTAssert(try content.tags.contains(tag.repository.requireID()))
        let secondElasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema)
        XCTAssertNotNil(secondElasticResponse)
        let secondContent = secondElasticResponse!.source
        XCTAssertEqual(secondContent.languagePriority, try setLanguagesPriorityContent.newLanguagesOrder.firstIndex(of: newLanguage.requireID())! + 1)
        XCTAssertEqual(secondContent.id, repository.id)
        XCTAssertEqual(secondContent.title, newDetail.title)
        XCTAssertEqual(secondContent.slug, newDetail.title.slugify())
        XCTAssertEqual(secondContent.detailText, newDetail.detailText)
        XCTAssertEqual(secondContent.languageId, newDetail.$language.id)
        XCTAssertEqual(secondContent.languageCode, newDetail.language.languageCode)
        XCTAssertEqual(secondContent.location.lat, location.latitude)
        XCTAssertEqual(secondContent.location.lon, location.longitude)
        XCTAssert(try secondContent.tags.contains(tag.repository.requireID()))
    }
    
    func testUpdateLanguageChangesAllItsWaypointssInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, location) = try await createNewWaypoint()
        try await detail.$language.load(on: app.db)
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let languageUpdateContent = Language.Detail.Update(languageCode: "updated language \(UUID())", name: "Some other name \(UUID())", isRTL: false)
        
        try app
            .describe("Update language should return ok and the created language")
            .put(languagesPath.appending(newLanguage.requireID().uuidString))
            .body(languageUpdateContent)
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        if let elasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema) {
            let content = elasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, detail.title)
            XCTAssertEqual(content.slug, detail.title.slugify())
            XCTAssertEqual(content.detailText, detail.detailText)
            XCTAssertEqual(content.location.lat, location.latitude)
            XCTAssertEqual(content.location.lon, location.longitude)
            XCTAssertEqual(content.languageId, detail.$language.id)
            XCTAssertEqual(content.languageCode, detail.language.languageCode)
            XCTAssertEqual(content.languageName, detail.language.name)
            XCTAssertEqual(content.languageIsRTL, detail.language.isRTL)
        } else {
            XCTFail()
        }
        if let secondElasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema) {
            let content = secondElasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, newDetail.title)
            XCTAssertEqual(content.slug, newDetail.title.slugify())
            XCTAssertEqual(content.detailText, newDetail.detailText)
            XCTAssertEqual(content.location.lat, location.latitude)
            XCTAssertEqual(content.location.lon, location.longitude)
            XCTAssertEqual(content.languageId, newDetail.$language.id)
            XCTAssertEqual(content.languageCode, languageUpdateContent.languageCode)
            XCTAssertEqual(content.languageName, languageUpdateContent.name)
            XCTAssertEqual(content.languageIsRTL, languageUpdateContent.isRTL)
        } else {
            XCTFail()
        }
    }
    
    func testDeleteUserUpdatesAllTheirWaypointDetailsInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, location) = try await createNewWaypoint()
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let user = try await getUser(role: .user)
        let newLanguage = try await createLanguage()
        let newDetail = try await detail.updateWith(languageId: newLanguage.requireID(), userId: user.requireID(), on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
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
        
        if let elasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema) {
            let content = elasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, detail.title)
            XCTAssertEqual(content.slug, detail.title.slugify())
            XCTAssertEqual(content.detailText, detail.detailText)
            XCTAssertEqual(content.location.lat, location.latitude)
            XCTAssertEqual(content.location.lon, location.longitude)
            XCTAssertEqual(content.languageId, detail.$language.id)
            XCTAssertEqual(content.detailUserId, detail.$user.id)
        } else {
            XCTFail()
        }
        if let secondElasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(newDetail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema) {
            let content = secondElasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, newDetail.title)
            XCTAssertEqual(content.slug, newDetail.title.slugify())
            XCTAssertEqual(content.detailText, newDetail.detailText)
            XCTAssertEqual(content.location.lat, location.latitude)
            XCTAssertEqual(content.location.lon, location.longitude)
            XCTAssertEqual(content.languageId, newDetail.$language.id)
            XCTAssertNil(content.detailUserId)
        } else {
            XCTFail()
        }
    }
    
    func testDeleteUserUpdatesAllTheirWaypointLocationsInElasticsearch() async throws {
        let adminToken = try await getToken(for: .admin)
        let (repository, detail, location) = try await createNewWaypoint()
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(location.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(detail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        let user = try await getUser(role: .user)
        let newDetail = try await detail.updateWith(userId: user.requireID(), on: app.db)
        let newLocation = try await location.updateWith(userId: user.requireID(), on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/waypoints/verify/\(newDetail.requireID())"))
            .bearerToken(adminToken)
            .expect(.ok)
            .expect(.json)
            .test()
        
        try app
            .describe("Verify location as moderator should be successful and return ok")
            .post(waypointsPath.appending("\(repository.requireID())/locations/verify/\(newLocation.requireID())"))
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
        
        if let elasticResponse = try? await app.elastic.get(document: WaypointSummaryModel.Elasticsearch.self, id: "\(repository.requireID())_\(detail.$language.id)", from: WaypointSummaryModel.Elasticsearch.schema) {
            let content = elasticResponse.source
            XCTAssertEqual(content.id, repository.id)
            XCTAssertEqual(content.title, newDetail.title)
            XCTAssertEqual(content.slug, newDetail.title.slugify())
            XCTAssertEqual(content.detailText, newDetail.detailText)
            XCTAssertEqual(content.location.lat, newLocation.latitude)
            XCTAssertEqual(content.location.lon, newLocation.longitude)
            XCTAssertEqual(content.languageId, newDetail.$language.id)
            XCTAssertNil(content.detailUserId)
            XCTAssertNil(content.locationUserId)
        } else {
            XCTFail()
        }
    }
}

