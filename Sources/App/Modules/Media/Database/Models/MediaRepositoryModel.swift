//
//  MediaRepositoryModel.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

final class MediaRepositoryModel: DatabaseModelInterface {
    typealias Module = WaypointModule
    
    static var identifier: String { "media_repositories" }
    
    struct FieldKeys {
        struct v1 {
            static var waypointId: FieldKey { "waypoint_id" }
        }
    }
    
    @ID() var id: UUID?
    @Children(for: \.$mediaRepository) var media: [MediaDescriptionModel]
    
    @Parent(key: FieldKeys.v1.waypointId) var waypoint: WaypointWaypointModel
    
    init() { }
}

extension MediaRepositoryModel {
    func media(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> MediaDescriptionModel? {
        var query = self.$media
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
    
    func media(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> MediaDescriptionModel? {
        for languageCode in languageCodesByPriority {
            if let waypoint = try await media(for: languageCode, needsToBeVerified: needsToBeVerified, on: db, sort: sortDirection){
                return waypoint
            }
        }
        return nil
    }
}
