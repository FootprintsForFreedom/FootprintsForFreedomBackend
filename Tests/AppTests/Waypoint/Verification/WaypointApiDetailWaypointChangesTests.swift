//
//  WaypointApiDetailWaypointChangesTests.swift
//  
//
//  Created by niklhut on 13.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiDetailWaypointChangesTests: AppTestCase, WaypointTest {
    func testSuccessfulDetailChanges() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointDetailModel.createWith(
            title: "Another different title \(UUID())",
            detailText: "This is a new detailText",
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verifiedAt: nil,
            on: app.db
        )
        try await waypointModel.$user.load(on: app.db)
        try await secondWaypointModel.$user.load(on: app.db)
        
        try app
            .describe("Detail changes as moderator should be succesfull and return ok")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Waypoint.Repository.Changes.self) { content in
                XCTAssertEqual(content.fromUser?.id, waypointModel.user?.id)
                XCTAssertEqual(content.toUser?.id, secondWaypointModel.user?.id)
            }
            .test()
    }
    
    func testDetailChangesAsUserFails() async throws {
        let userToken = try await getToken(for: .user)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointDetailModel.createWith(
            title: "Another different title \(UUID())",
            detailText: "This is a new detailText",
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verifiedAt: nil,
            on: app.db
        )
        
        try app
            .describe("Detail changes as user should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDetailChangesWithoutTokenFails() async throws {
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointDetailModel.createWith(
            title: "Another different title \(UUID())",
            detailText: "This is a new detailText",
            repositoryId: waypointRepository.requireID(),
            languageId: language.requireID(),
            userId: user.requireID(),
            verifiedAt: nil,
            on: app.db
        )
        
        try app
            .describe("Detail wihtout token should fail")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testDetailChangesMustContainFromId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint()
        
        try  app
            .describe("Detail changes request must contain from id field")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?to=\(waypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testDetailChangesMustContainToId() async throws {
        let moderatorToken = try await getToken(for: .admin)
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint()
        
        try  app
            .describe("Detail changes request must contain to id field")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?from=\(waypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
    
    func testFromDetailChangesMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (_, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        let (waypointRepository2, waypointModel2, _) = try await createNewWaypoint(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when from model is from other repository")
            .get(waypointsPath.appending("\(waypointRepository2.requireID())/waypoints/changes/?from=\(waypointModel.requireID())&to=\(waypointModel2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testToDetailChangesMustBelongToSpecifiedRepositoryId() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let language =  try await createLanguage()
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        let (_, waypointModel2, _) = try await createNewWaypoint(languageId: language.requireID())
        
        try app
            .describe("Detail changes should fail when to model is from other repository")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?from=\(waypointModel.requireID())&to=\(waypointModel2.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    func testDetailChangesWithModelsFromDifferntLanguagesFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        
        let user = try await getUser(role: .user)
        let language =  try await createLanguage()
        let secondLanguage =  try await createLanguage()
        let (waypointRepository, waypointModel, _) = try await createNewWaypoint(languageId: language.requireID())
        let secondWaypointModel = try await WaypointDetailModel.createWith(
            title: "Another different title",
            detailText: "This is a new detailText",
            repositoryId: waypointRepository.requireID(),
            languageId: secondLanguage.requireID(),
            userId: user.requireID(),
            verifiedAt: nil,
            on: app.db
        )
        
        try app
            .describe("Detail changes should fail when models have different languages")
            .get(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/changes/?from=\(waypointModel.requireID())&to=\(secondWaypointModel.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
