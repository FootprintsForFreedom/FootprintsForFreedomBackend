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
    
    init() { }
}

extension WaypointRepositoryModel {
    func latestWaypointModel(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        loadDescription: Bool
    ) async throws -> WaypointWaypointModel? {
        var query = self.$waypoints
            .query(on: db)
            .join(LanguageModel.self, on: \WaypointWaypointModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$languageCode == languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        if needsToBeVerified {
            query = query.filter(\.$verified == true)
        }
        query = query
            .sort(\.$updatedAt, .descending) // newest first
            .with(\.$title)
            .with(\.$location)
            .with(\.$language)
        
        if loadDescription {
            query = query.with(\.$description)
        }
        
        return try await query.first()
    }
    
    func latestWaypointModel(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        loadDescription: Bool
    ) async throws -> WaypointWaypointModel? {
        for languageCode in languageCodesByPriority {
            if let waypoint = try await latestWaypointModel(for: languageCode, needsToBeVerified: needsToBeVerified, on: db, loadDescription: loadDescription){
                return waypoint
            }
        }
        return nil
    }
}
