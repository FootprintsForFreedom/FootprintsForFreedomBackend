//
//  WaypointApiVerifyTests.swift
//  
//
//  Created by niklhut on 13.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiVerifyTests: AppTestCase {
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
    
    func testSuccessfulVerifyWaypoint() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let (waypointRepository, waypointModel) = try await createNewWaypoint()
        try await waypointModel.load(on: app.db)
        
        try app
            .describe("Verify waypoint as moderator should be successfull and return ok")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/verify/\(waypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Waypoint.Detail.self) { content in
                XCTAssertEqual(content.id, waypointRepository.id)
                XCTAssertEqual(content.title, waypointModel.title.value)
                XCTAssertEqual(content.description, waypointModel.description.value)
                XCTAssertEqual(content.location, waypointModel.location.value)
                XCTAssertEqual(content.languageCode, waypointModel.language.languageCode)
                XCTAssertEqual(content.verified, true)
            }
            .test()
    }
    
    func testVerifyWaypointAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        let (waypointRepository, waypointModel) = try await createNewWaypoint()
        
        try app
            .describe("Verify waypoint as user should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/verify/\(waypointModel.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyWaypointWithoutTokenFails() async throws {
        let (waypointRepository, waypointModel) = try await createNewWaypoint()
        
        try app
            .describe("Verify waypoint without token should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/verify/\(waypointModel.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyWaypointWithAlreadyVerifiedWaypointFails() async throws {
        let userToken = try await getToken(for: .moderator)
        let (waypointRepository, waypointModel) = try await createNewWaypoint(verified: true)
        
        try app
            .describe("Verify waypoint for already verified waypoint should fail")
            .post(waypointsPath.appending("\(waypointRepository.requireID())/verify/\(waypointModel.requireID())"))
            .bearerToken(userToken)
            .expect(.badRequest)
            .test()
    }
}
