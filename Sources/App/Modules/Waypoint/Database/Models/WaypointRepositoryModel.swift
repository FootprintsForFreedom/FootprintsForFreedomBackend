//
//  WaypointRepositoryModel.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import Vapor
import Fluent

final class WaypointRepositoryModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    static var identifier: String { "repositories" }
    
    @ID() var id: UUID?
    @Children(for: \.$repository) var waypoints: [WaypointWaypointModel]
    @Children(for: \.$repository) var locations: [WaypointLocationModel]
    @Children(for: \.$waypoint) var media: [MediaRepositoryModel]
    
    init() { }
}

extension WaypointRepositoryModel {
    func location(
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> WaypointLocationModel? {
        var query = self.$locations.query(on: db)
        if needsToBeVerified {
            query = query.filter(\.$verified == true)
        }
        query = query.sort(\.$updatedAt, sortDirection)
        return try await query.first()
    }
    
    func waypointModel(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> WaypointWaypointModel? {
        var query = self.$waypoints
            .query(on: db)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$languageCode == languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        if needsToBeVerified {
            query = query.filter(\.$verified == true)
        }
        query = query.sort(\.$updatedAt, sortDirection)
        
        return try await query.first()
    }
    
    func waypointModel(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> WaypointWaypointModel? {
        for languageCode in languageCodesByPriority {
            if let waypoint = try await waypointModel(for: languageCode, needsToBeVerified: needsToBeVerified, on: db, sort: sortDirection){
                return waypoint
            }
        }
        return nil
    }
}
