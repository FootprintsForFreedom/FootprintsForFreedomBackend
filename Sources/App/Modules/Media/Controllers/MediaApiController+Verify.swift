//
//  MediaApiController+Verify.swift
//  
//
//  Created by niklhut on 17.05.22.
//

import Vapor
import Fluent
import DiffMatchPatch

extension Media.Repository.Changes: Content { }

extension MediaApiController {
    // GET: api/media/:mediaId/changes/?from=modelId1&to=modelId2
    func detailChanges(_ req: Request) async throws -> Media.Repository.Changes {
        try await req.onlyFor(.moderator)
        
        let repository = try await detail(req)
        let detailChangesRequest = try req.query.decode(Media.Repository.DetailChangesRequest.self)
        
        guard
            let fromId = detailChangesRequest.from,
            let toId = detailChangesRequest.to
        else {
            throw Abort(.badRequest)
        }
        
        guard
            let model1 = try await MediaDescriptionModel
                .query(on: req.db)
                .filter(\.$mediaRepository.$id == repository.requireID())
                .filter(\._$id == fromId)
                .with(\.$user)
                .with(\.$media)
                .first(),
            let model2 = try await MediaDescriptionModel
                .query(on: req.db)
                .filter(\.$mediaRepository.$id == repository.requireID())
                .filter(\._$id == toId)
                .with(\.$user)
                .with(\.$media)
                .first()
        else {
            throw Abort(.notFound)
        }
        
        guard model1.$language.id == model2.$language.id else {
            throw Abort(.badRequest, reason: "The models need to be of the same language")
        }
        
        /// compute the diffs
        let titleDiff = computeDiff(model1.title, model2.title)
            .cleaningUpSemantics()
            .converted()
        let descriptionDiff = computeDiff(model1.description, model2.description)
            .cleaningUpSemantics()
            .converted()
        let sourceDiff = computeDiff(model1.source, model2.source)
            .cleaningUpSemantics()
            .converted()
        
        let model1User = try User.Account.Detail.publicDetail(id: model1.user.requireID(), name: model1.user.name, school: model1.user.school)
        let model2User = try User.Account.Detail.publicDetail(id: model2.user.requireID(), name: model2.user.name, school: model2.user.school)
        
        return .init(
            titleDiff: titleDiff,
            descriptionDiff: descriptionDiff,
            sourceDiff: sourceDiff,
            fromGroup: model1.media.group,
            toGroup: model2.media.group,
            fromFilePath: model1.media.mediaDirectory,
            toFilePath: model2.media.mediaDirectory,
            fromUser: model1User,
            toUser: model2User
        )
    }
    
    func listRepositoriesWithUnverifiedModels(_ req: Request) async throws -> Page<Media.Media.List> {
        try await req.onlyFor(.moderator)
        
        // TODO: simplify the following language code statements for all models -> something like req.getAllLanguageCodesByPriority
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        let repositoriesWithUnverifiedModels = try await MediaRepositoryModel
            .query(on: req.db)
            .join(MediaDescriptionModel.self, on: \MediaDescriptionModel.$mediaRepository.$id == \WaypointRepositoryModel.$id)
            .join(LanguageModel.self, on: \MediaDescriptionModel.$language.$id == \LanguageModel.$id)
            .filter(MediaDescriptionModel.self, \.$verified == false)
            .filter(LanguageModel.self, \.$priority != nil)
            .field(\.$id)
            .unique()
            .paginate(for: req)
        
        return try await repositoriesWithUnverifiedModels.concurrentMap { repository in
            let latestVerifiedMedia = try await repository.media(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db, sort: .ascending)
            var media: MediaDescriptionModel! = latestVerifiedMedia
            if media == nil {
                guard let oldestUnverifiedMedia = try await repository.media(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db, sort: .ascending) else {
                    throw Abort(.internalServerError)
                }
                media = oldestUnverifiedMedia
            }
            
            return try .init(
                id: repository.requireID(),
                title: media.title,
                group: media.media.group
            )
        }
    }
    
    
    func listUnverifiedMediaModels(_ req: Request) async throws -> Page<Media.Repository.ListUnverified> {
        try await req.onlyFor(.moderator)
        
        let repository = try await detail(req)
        
        let unverifiedMediaModels = try await repository.$media
            .query(on: req.db)
            .filter(\.$verified == false)
            .sort(\.$updatedAt, .ascending) // oldest first
            .with(\.$language)
            .paginate(for: req)
        
        return try unverifiedMediaModels.map { media in
            return try .init(
                modelId: media.requireID(),
                title: media.title,
                description: media.description,
                languageCode: media.language.languageCode)
        }
    }
    
    var newModelPathIdKey: String { "newModel" }
    var newModelPathIdComponent: PathComponent { .init(stringLiteral: ":" + newModelPathIdKey) }
    
    // POST: api/media/:repositoryId/verify/:waypointModelId
    func verifyWaypoint(_ req: Request) async throws -> Media.Media.Detail {
        try await req.onlyFor(.moderator)
        
        let repository = try await detail(req)
        guard
            let waypointIdString = req.parameters.get(newModelPathIdKey),
            let waypointId = UUID(uuidString: waypointIdString)
        else {
            throw Abort(.badRequest)
        }
        
        guard let media = try await MediaDescriptionModel
            .query(on: req.db)
            .filter(\._$id == waypointId)
            .filter(\.$mediaRepository.$id == repository.requireID())
            .filter(\.$verified == false)
            .with(\.$language)
            .with(\.$media)
            .first()
        else {
            throw Abort(.badRequest)
        }
        media.verified = true
        try await media.update(on: req.db)
        
        return try .moderatorDetail(
            id: repository.requireID(),
            languageCode: media.language.languageCode,
            title: media.title,
            description: media.description,
            source: media.source,
            group: media.media.group,
            filePath: media.media.mediaDirectory,
            verified: media.verified, // TODO: && media.file.verififed
            descriptionId: media.requireID()
        )
    }
    
    func setupVerificationRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("unverified", use: listRepositoriesWithUnverifiedModels)
        
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get("unverified", use: listUnverifiedMediaModels)
        existingModelRoutes.get("changes", use: detailChanges)
        existingModelRoutes.grouped("verify")
            .grouped(newModelPathIdComponent)
            .post(use: verifyWaypoint)
    }
}
