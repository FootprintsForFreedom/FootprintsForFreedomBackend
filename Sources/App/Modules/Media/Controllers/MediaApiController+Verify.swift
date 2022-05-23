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
    
    @AsyncValidatorBuilder
    func detailChangesValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("from", validateQuery: true)
        KeyedContentValidator<String>.required("to", validateQuery: true)
    }
    
    // GET: api/media/:mediaId/changes/?from=modelId1&to=modelId2
    func detailChanges(_ req: Request) async throws -> Media.Repository.Changes {
        try await req.onlyFor(.moderator)
        
        let repository = try await detail(req)
        try await RequestValidator(detailChangesValidators()).validate(req)
        let detailChangesRequest = try req.query.decode(Media.Repository.DetailChangesRequest.self)
        
        guard
            let model1 = try await MediaDetailModel
                .query(on: req.db)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\._$id == detailChangesRequest.from)
                .with(\.$user)
                .with(\.$media)
                .first(),
            let model2 = try await MediaDetailModel
                .query(on: req.db)
                .filter(\.$repository.$id == repository.requireID())
                .filter(\._$id == detailChangesRequest.to)
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
        let detailTextDiff = computeDiff(model1.detailText, model2.detailText)
            .cleaningUpSemantics()
            .converted()
        let sourceDiff = computeDiff(model1.source, model2.source)
            .cleaningUpSemantics()
            .converted()
        
        let model1User = try User.Account.Detail.publicDetail(id: model1.user.requireID(), name: model1.user.name, school: model1.user.school)
        let model2User = try User.Account.Detail.publicDetail(id: model2.user.requireID(), name: model2.user.name, school: model2.user.school)
        
        return .init(
            titleDiff: titleDiff,
            detailTextDiff: detailTextDiff,
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
        let allLanguageCodesByPriority = try await req.allLanguageCodesByPriority()
        
        let repositoriesWithUnverifiedModels = try await MediaRepositoryModel
            .query(on: req.db)
            .join(MediaDetailModel.self, on: \MediaDetailModel.$repository.$id == \MediaRepositoryModel.$id)
            .join(LanguageModel.self, on: \MediaDetailModel.$language.$id == \LanguageModel.$id)
            .filter(MediaDetailModel.self, \.$verified == false)
            .filter(LanguageModel.self, \.$priority != nil)
            .field(\.$id)
            .unique()
            .paginate(for: req)
        
        return try await repositoriesWithUnverifiedModels.concurrentMap { repository in
            let latestVerifiedMedia = try await repository.media(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db, sort: .ascending)
            var media: MediaDetailModel! = latestVerifiedMedia
            if media == nil {
                guard let oldestUnverifiedMedia = try await repository.media(for: allLanguageCodesByPriority, needsToBeVerified: false, on: req.db, sort: .ascending) else {
                    throw Abort(.internalServerError)
                }
                media = oldestUnverifiedMedia
            }
            
            try await media.$media.load(on: req.db)
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
                detailText: media.detailText,
                languageCode: media.language.languageCode)
        }
    }
    
    var newModelPathIdKey: String { "newModel" }
    var newModelPathIdComponent: PathComponent { .init(stringLiteral: ":" + newModelPathIdKey) }
    
    // POST: api/media/:repositoryId/verify/:waypointModelId
    func verifyMedia(_ req: Request) async throws -> Media.Media.Detail {
        try await req.onlyFor(.moderator)
        
        let repository = try await detail(req)
        guard
            let waypointIdString = req.parameters.get(newModelPathIdKey),
            let waypointId = UUID(uuidString: waypointIdString)
        else {
            throw Abort(.badRequest)
        }
        
        guard let media = try await MediaDetailModel
            .query(on: req.db)
            .filter(\._$id == waypointId)
            .filter(\.$repository.$id == repository.requireID())
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
            detailText: media.detailText,
            source: media.source,
            group: media.media.group,
            filePath: media.media.mediaDirectory,
            verified: media.verified, // TODO: && media.file.verififed
            detailId: media.requireID()
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
            .post(use: verifyMedia)
    }
}
