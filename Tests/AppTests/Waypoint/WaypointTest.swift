//
//  WaypointTest.swift
//  
//
//  Created by niklhut on 21.03.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

protocol WaypointTest: LanguageTest { }

extension WaypointTest {
    var waypointsPath: String { "api/v1/waypoints/" }
    
    func createNewWaypoint(
        title: String = "New Waypoint Title \(UUID())",
        detailText: String = "New Waypoint detail text",
        location: Waypoint.Location = .init(latitude: Double.random(in: -90...90), longitude: Double.random(in: -180...180)),
        verified: Bool = false,
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
            verified: false,
            on: self
        )
        let location = try await WaypointLocationModel.createWith(
            location: location,
            repositoryId: waypointRepository.requireID(),
            userId: userId,
            verified: false,
            on: self
        )
        
        if verified {
            try app
                .describe("Verify waypoint detail as moderator should be successful and return ok")
                .post(waypointsPath.appending("\(waypointRepository.requireID())/waypoints/verify/\(waypointModel.requireID())"))
                .bearerToken(moderatorToken)
                .expect(.ok)
                .expect(.json)
                .expect(Waypoint.Detail.Detail.self) { content in
                    waypointModel.slug = content.slug
                }
                .test()
            
            try app
                .describe("Verify waypoint location as moderator should be successful and return ok")
                .post(waypointsPath.appending("\(waypointRepository.requireID())/locations/verify/\(location.requireID())"))
                .bearerToken(moderatorToken)
                .expect(.ok)
                .expect(.json)
                .test()
        }
        
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
        verified: Bool,
        on test: WaypointTest
    ) async throws -> Self {
        let slug = slug ?? title.appending(" ").appending(Date().toString(with: .day)).slugify()
        let waypoint = self.init(
            verifiedAt: nil,
            title: title,
            slug: slug,
            detailText: detailText,
            languageId: languageId,
            repositoryId: repositoryId,
            userId: userId
        )
        try await waypoint.create(on: test.app.db)
        
        if verified {
            try test.app
                .describe("Verify waypoint detail as moderator should be successful and return ok")
                .post(test.waypointsPath.appending("\(repositoryId)/waypoints/verify/\(waypoint.requireID())"))
                .bearerToken(test.moderatorToken)
                .expect(.ok)
                .expect(.json)
                .expect(Waypoint.Detail.Detail.self) { content in
                    waypoint.slug = content.slug
                }
                .test()
        }
        
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
        verified: Bool,
        on test: WaypointTest
    ) async throws -> Self {
        let location = self.init(
            verifiedAt: nil,
            latitude: location.latitude,
            longitude: location.longitude,
            repositoryId: repositoryId,
            userId: userId
        )
        try await location.create(on: test.app.db)
        
        if verified {
            try test.app
                .describe("Verify waypoint location as moderator should be successful and return ok")
                .post(test.waypointsPath.appending("\(repositoryId)/locations/verify/\(location.requireID())"))
                .bearerToken(test.moderatorToken)
                .expect(.ok)
                .expect(.json)
                .test()
        }
        
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
