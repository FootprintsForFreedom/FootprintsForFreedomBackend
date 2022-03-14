//
//  WaypointApiDetailChangesTests.swift
//  
//
//  Created by niklhut on 13.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiDetailChangesTests: AppTestCase {
    let waypointsPath = "api/waypoints/"
    
    private func createLanguage(
        languageCode: String = UUID().uuidString,
        name: String = UUID().uuidString,
        isRTL: Bool = false
    ) async throws -> LanguageModel {
        let highestPriority = try await LanguageModel
            .query(on: app.db)
            .filter(\.$priority != nil)
            .sort(\.$priority, .descending)
            .first()?.priority ?? 0
        
        let language = LanguageModel(languageCode: languageCode, name: name, isRTL: isRTL, priority: highestPriority + 1)
        try await language.create(on: app.db)
        return language
    }
    
    private func createNewWaypoint(
        title: String = "New Waypoint Title",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: WaypointRepositoryModel, model: WaypointWaypointModel) {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        let waypointRepository = WaypointRepositoryModel()
        try await waypointRepository.create(on: app.db)
        
        let languageId: UUID = try await {
            if let languageId = languageId {
                return languageId
            } else {
                return try await createLanguage().requireID()
            }
        }()
        
        let waypointModel = try await WaypointWaypointModel.createWith(
            title: title,
            description: description,
            location: location,
            repositoryId: waypointRepository.requireID(),
            languageId: languageId,
            userId: userId,
            verified: verified,
            on: app.db
        )
        return (waypointRepository, waypointModel)
    }
    
    func testSuccessfulDetailChanges() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointWaypointModel.createWith(
            title: "Another different title",
            description: "This is a new description",
            location: .init(latitude: 9, longitude: 20),
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verified: false,
            on: app.db
        )
        
        try await waypointModel.load(on: app.db)
        try await secondWaypointModel.load(on: app.db)
        
        try app
            .describe("Detail changes as moderator should be succesfull and return ok")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Changes.self) { content in
                XCTAssertEqual(content.oldLocation, waypointModel.location.value)
                XCTAssertEqual(content.newLocation, secondWaypointModel.location.value)
                XCTAssertEqual(content.fromUser.id, waypointModel.user.id)
                XCTAssertEqual(content.toUser.id, secondWaypointModel.user.id)
            }
            .test()
    }
    
    func testDetailChangesOnlyContainsNewLocationWhenItChanged() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        try await waypointModel.load(on: app.db)
        
        let secondWaypointModel = try await WaypointWaypointModel.createWith(
            title: "Another different title",
            description: "This is a new description",
            location: waypointModel.location.value,
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verified: false,
            on: app.db
        )
        try await secondWaypointModel.load(on: app.db)
        
        try app
            .describe("Detail changes should not return new Location when it did not change")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Changes.self) { content in
                XCTAssertEqual(content.oldLocation, waypointModel.location.value)
                XCTAssertNil(content.newLocation)
                XCTAssertEqual(content.fromUser.id, waypointModel.user.id)
                XCTAssertEqual(content.toUser.id, secondWaypointModel.user.id)
            }
            .test()
    }
    
    func testDetailChangesAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointWaypointModel.createWith(
            title: "Another different title",
            description: "This is a new description",
            location: .init(latitude: 9, longitude: 20),
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verified: false,
            on: app.db
        )
        
        try app
            .describe("Detail changes as user should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDetailChangesWithoutTokenFails() async throws {
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointWaypointModel.createWith(
            title: "Another different title",
            description: "This is a new description",
            location: .init(latitude: 9, longitude: 20),
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verified: false,
            on: app.db
        )
        
        try app
            .describe("Detail wihtout token should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDetailChangesMustContainFromAndToId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (waypointRepository, _) = try await createNewWaypoint()
        
        try  app
            .describe("Detail changes request must contain from and to id field")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testFromDetailChangesMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (_, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        let (waypointRepository2, waypointModel2) = try await createNewWaypoint(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when from model is from other repository")
            .get(waypointsPath.appending("\(waypointRepository2.requireID())/changes/?from=\(waypointModel.requireID())&to=\(waypointModel2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testToDetailChangesMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        let (_, waypointModel2) = try await createNewWaypoint(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when to model is from other repository")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/?from=\(waypointModel.requireID())&to=\(waypointModel2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesWithModelsFromDifferntLanguagesFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let secondLanguage =  try await createLanguage()
        let (waypointRepository, waypointModel) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointWaypointModel.createWith(
            title: "Another different title",
            description: "This is a new description",
            location: .init(latitude: 9, longitude: 20),
            repositoryId: waypointRepository.requireID(),
            languageId: secondLanguage.requireID(),
            userId: user.requireID(),
            verified: false,
            on: app.db
        )
        
        try app
            .describe("Detail changes should fail when models have different languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
