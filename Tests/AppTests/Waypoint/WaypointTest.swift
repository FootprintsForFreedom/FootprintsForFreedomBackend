//
//  WaypointTest.swift
//  
//
//  Created by niklhut on 21.03.22.
//

@testable import App
import XCTVapor
import Fluent

protocol WaypointTest: LanguageTest { }

extension WaypointTest {
    var waypointsPath: String { "api/v1/waypoints/" }
    
    func createNewWaypoint(
        title: String = "New Waypoint Title \(UUID())",
        detailText: String = "New Waypoint detail text",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verifiedAt: Date? = nil,
        languageId: UUID? = nil,
        userId: UUID? = nil
    ) async throws -> (repository: WaypointRepositoryModel, detail: WaypointDetailModel, location: WaypointLocationModel) {
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
        
        let waypointModel = try await WaypointDetailModel.createWith(
            title: title,
            detailText: detailText,
            repositoryId: waypointRepository.requireID(),
            languageId: languageId,
            userId: userId,
            verifiedAt: verifiedAt,
            on: app.db
        )
        let location = try await WaypointLocationModel.createWith(
            location: location,
            repositoryId: waypointRepository.requireID(),
            userId: userId,
            verifiedAt: verifiedAt,
            on: app.db
        )
        
        return (waypointRepository, waypointModel, location)
    }
}

extension WaypointDetailModel {
    static func createWith(
        title: String,
        slug: String? = nil,
        detailText: String,
        repositoryId: UUID,
        languageId: UUID,
        userId: UUID,
        verifiedAt: Date?,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let waypoint = self.init(
            verifiedAt: verifiedAt,
            title: title,
            slug: slug,
            detailText: detailText,
            languageId: languageId,
            repositoryId: repositoryId,
            userId: userId
        )
        try await waypoint.create(on: db)
        return waypoint
    }
    
    @discardableResult
    func updateWith(
        title: String = "Updated Waypoint Title \(UUID())",
        slug: String? = nil,
        detailText: String = "Updated Waypoint detail text",
        languageId: UUID? = nil,
        userId: UUID? = nil,
        verifiedAt: Date? = nil,
        on db: Database
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let waypoint = Self.init(
            verifiedAt: verifiedAt,
            title: title,
            slug: slug,
            detailText: detailText,
            languageId: languageId ?? self.$language.id,
            repositoryId: self.$repository.id,
            userId: userId ?? self.$user.id!
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
        verifiedAt: Date?,
        on db: Database
    ) async throws -> Self {
        let location = self.init(
            verifiedAt: verifiedAt,
            latitude: location.latitude,
            longitude: location.longitude,
            repositoryId: repositoryId,
            userId: userId
        )
        try await location.create(on: db)
        return location
    }
    
    @discardableResult
    func updateWith(
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        userId: UUID? = nil,
        verifiedAt: Date? = nil,
        on db: Database
    ) async throws -> Self {
        let location = Self.init(
            verifiedAt: verifiedAt,
            latitude: location.latitude,
            longitude: location.longitude,
            repositoryId: self.$repository.id,
            userId: userId ?? self.$user.id!
        )
        try await location.create(on: db)
        return location
    }
}
