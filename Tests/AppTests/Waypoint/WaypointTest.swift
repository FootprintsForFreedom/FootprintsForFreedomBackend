//
//  WaypointTest.swift
//  
//
//  Created by niklhut on 21.03.22.
//

@testable import App
import Fluent

protocol WaypointTest: LanguageTest { }

extension WaypointTest {
    func createNewWaypoint(
        title: String = "New Waypoint Title",
        description: String = "New Waypoint Description",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: WaypointRepositoryModel, model: WaypointWaypointModel, location: WaypointLocationModel) {
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
            repositoryId: waypointRepository.requireID(),
            languageId: languageId,
            userId: userId,
            verified: verified,
            on: app.db
        )
        let location = try await WaypointLocationModel.createWith(
            location: location,
            repositoryId: waypointRepository.requireID(),
            userId: userId,
            verified: verified,
            on: app.db
        )
        
        return (waypointRepository, waypointModel, location)
    }
}

extension WaypointWaypointModel {
    static func createWith(
        title: String,
        description: String,
        repositoryId: UUID,
        languageId: UUID,
        userId: UUID,
        verified: Bool,
        on db: Database
    ) async throws -> Self {
        let waypoint = self.init(
            verified: verified,
            title: title,
            description: description,
            languageId: languageId,
            repositoryId: repositoryId,
            userId: userId
        )
        try await waypoint.create(on: db)
        return waypoint
    }
}

extension WaypointLocationModel {
    static func createWith(
        location: Waypoint.Location,
        repositoryId: UUID,
        userId: UUID,
        verified: Bool,
        on db: Database
    ) async throws -> Self {
        let location = self.init(
            verified: verified,
            latitude: location.latitude,
            longitude: location.longitude,
            repositoryId: repositoryId,
            userId: userId
        )
        try await location.create(on: db)
        return location
    }
}
