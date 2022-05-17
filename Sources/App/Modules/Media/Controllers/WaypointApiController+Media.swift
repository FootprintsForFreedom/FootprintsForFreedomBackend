//
//  WaypointApiController+Media.swift
//  
//
//  Created by niklhut on 17.05.22.
//

import Vapor
import Fluent

extension WaypointApiController {
    func listMedia(_ req: Request) async throws -> Page<Media.Media.List> {
        let waypointRepository = try await detail(req)
        let mediaRepositories = try await waypointRepository.$media
            .query(on: req.db)
            .join(MediaDescriptionModel.self, on: \MediaDescriptionModel.$mediaRepository.$id == \MediaRepositoryModel.$id)
            .filter(MediaDescriptionModel.self, \.$verified == true)
            .join(LanguageModel.self, on: \MediaDescriptionModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
            .field(\.$id)
            .unique()
            .paginate(for: req)
        
        return try await MediaApiController().listOutput(req, mediaRepositories)
    }
    
    func setupMediaRoute(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get("media", use: listMedia)
    }
}
