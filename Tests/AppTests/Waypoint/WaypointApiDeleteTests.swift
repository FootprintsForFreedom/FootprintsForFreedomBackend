//
//  WaypointApiDeleteTests.swift
//  
//
//  Created by niklhut on 19.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class WaypointApiDeleteTests: AppTestCase {
    let waypointsPath = "api/waypoints/"
    
    private func createNewWaypoint(
        title: String = "New Waypoint Title",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
        userId: UUID? = nil
    ) async throws -> WaypointRepositoryModel {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let waypointModel = try await WaypointWaypointModel.createWith(title: title, description: description, location: location, userId: userId, on: app.db)
        let waypointRepository = WaypointRepositoryModel()
        waypointRepository.verified = false
        waypointRepository.currentProperty.id = try waypointModel.requireID()
        waypointRepository.lastProperty.id = try waypointModel.requireID()
        try await waypointRepository.create(on: app.db)
        return waypointRepository
    }
    
    func testSuccessfullDeleteUnverifiedWaypointAsModerator() async throws {
        // Get original waypoint count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        let waypoint = try await createNewWaypoint()
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("A moderator should be able to delete a unverified waypoint")
            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
    }
    
    func testSuccessfullDeleteVerifiedWaypointAsModerator() async throws {
        // Get original waypoint count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        
        let waypoint = try await createNewWaypoint(verified: true)
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("A moderator should be able to delete a verified waypoint")
            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
    }
    
    func testDeleteWaypointRepositoryDeletesModels() async throws {
        // Get original waypoint repository and model count
        let waypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let waypointModelCount = try await WaypointWaypointModel.query(on: app.db).count()
        let editableObjectCount = try await EditableObjectModel<String>.query(on: app.db).count()
        
        let waypoint = try await createNewWaypoint(verified: true)
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("A moderator should be able to delete a verified waypoint")
            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.noContent)
            .test()
        
        // New waypoint count should be one less than original waypoint count
        let newWaypointCount = try await WaypointRepositoryModel.query(on: app.db).count()
        let newWaypointModelCount = try await WaypointWaypointModel.query(on: app.db).count()
        let newEditableObjectCount = try await EditableObjectModel<String>.query(on: app.db).count()
        XCTAssertEqual(newWaypointCount, waypointCount)
        XCTAssertEqual(newWaypointModelCount, waypointModelCount)
        XCTAssertEqual(newEditableObjectCount, editableObjectCount)
        
        // TODO: confirm this is also the case after updates
    }
    
    func testDeleteUnverifiedWaypointAsCreatorFails() async throws {
        let user = try await getUser(role: .user)
        let userToken = try user.generateToken()
        try await userToken.create(on: app.db)
        let waypoint = try await createNewWaypoint(userId: user.requireID())
        
        try app
            .describe("A user should not be able to delete a waypoint")
            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(userToken.value)
            .expect(.forbidden)
            .test()
    }
    
    
    func testDeleteWaypointAsUserFails() async throws {
        let waypoint = try await createNewWaypoint()
        let userToken = try await getTokenFromOtherUser(role: .user)
        
        try app
            .describe("A user should not be able to delete a waypoint")
            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
            .bearerToken(userToken)
            .expect(.forbidden)
            .test()
    }
    
    func testDeleteWihtoutTokenFails() async throws {
        let waypoint = try await createNewWaypoint()
        
        try app
            .describe("Delete waypoint without token fails")
            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
            .expect(.unauthorized)
            .test()
    }
    
    func testDeleteNonExistingWaypointFails() async throws {
        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
        
        try app
            .describe("Delete waypoint without token fails")
            .delete(waypointsPath.appending(UUID().uuidString))
            .bearerToken(moderatorToken)
            .expect(.notFound)
            .test()
    }
    
    //    func testDeleteWaypointDeletesAssociatedMedia() async throws {
    //        let waypoint = try await createNewWaypoint()
    //        let moderatorToken = try await getTokenFromOtherUser(role: .moderator)
    //
    ////        let media = WaypointMediaModel(
    //
    //        // Get original waypoint count
    //        let waypointCount = try await WaypointWaypointModel.query(on: app.db).count()
    //
    //        try app
    //            .describe("A moderator should be able to delete a unverified waypoint")
    //            .delete(waypointsPath.appending(waypoint.requireID().uuidString))
    //            .bearerToken(moderatorToken)
    //            .expect(.noContent)
    //            .test()
    //
    //        // New waypoint count should be one less than original waypoint count
    //        let newWaypointCount = try await WaypointWaypointModel.query(on: app.db).count()
    //        XCTAssertEqual(newWaypointCount, waypointCount - 1)
    //    }
    // TODO: delete waypoint deletes media of that waypoint
    // could already be solved by cascade in migrations but test it
}
