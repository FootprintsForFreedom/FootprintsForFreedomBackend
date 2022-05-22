//
//  MediaApiController.swift
//
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent

extension Media.Media.List: Content { }
extension Media.Media.Detail: Content { }

struct MediaApiController: ApiController {
    typealias ApiModel = Media.Media
    typealias DatabaseModel = MediaRepositoryModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", validateQuery: true)
        KeyedContentValidator<String>.required("detailText", validateQuery: true)
        KeyedContentValidator<String>.required("source", validateQuery: true)
        KeyedContentValidator<String>.required("languageCode", validateQuery: true)
        KeyedContentValidator<UUID>.required("waypointId", validateQuery: true)
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", validateQuery: true)
        KeyedContentValidator<String>.required("detailText", validateQuery: true)
        KeyedContentValidator<String>.required("source", validateQuery: true)
        KeyedContentValidator<String>.required("languageCode", validateQuery: true)
    }
    
    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: true, validateQuery: true)
        KeyedContentValidator<String>.required("detailText", optional: true, validateQuery: true)
        KeyedContentValidator<String>.required("source", optional: true, validateQuery: true)
        KeyedContentValidator<UUID>.required("idForMediaToPatch", validateQuery: true)
    }
    
    // MARK: - Routes
    
    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
        routes.grouped("media")
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(routes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
    
    // MARK: - List
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<MediaRepositoryModel>) async throws -> QueryBuilder<MediaRepositoryModel> {
        queryBuilder
        // only return repositories with verified media details inside
            .join(MediaDetailModel.self, on: \MediaDetailModel.$mediaRepository.$id == \MediaRepositoryModel.$id)
            .filter(MediaDetailModel.self, \.$verified == true)
        // only return media details which have a activated language
            .join(LanguageModel.self, on: \MediaDetailModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
            .field(\.$id)
            .unique()
    }
    
    func listOutput(_ req: Request, _ models: Page<MediaRepositoryModel>) async throws -> Page<Media.Media.List> {
        // TODO: sort?
        let allLanguageCodesByPriority = try await req.allLanguageCodesByPriority()
        
        return try await models
            .concurrentMap { model in
                guard let mediaDetail = try await model.media(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db) else {
                    return nil
                }
                
                // TODO: is this a bottleneck for the time it takes to return a result?
                try await mediaDetail.$media.load(on: req.db)
                return .init(
                    id: try model.requireID(),
                    title: mediaDetail.title,
                    group: mediaDetail.media.group
                )
            }
            .compactMap { $0 }
    }
    
    // MARK: - Detail
    
    func detailOutput(_ req: Request, _ repository: MediaRepositoryModel) async throws -> Media.Media.Detail {
        let allLanguageCodesByPriority = try await req.allLanguageCodesByPriority()
        
        guard let mediaDetail = try await repository.media(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db), user.role >= .moderator {
            try await mediaDetail.$media.load(on: req.db)
            try await mediaDetail.$language.load(on: req.db)
            
            return try .moderatorDetail(
                id: repository.requireID(),
                languageCode: mediaDetail.language.languageCode,
                title: mediaDetail.title,
                detailText: mediaDetail.detailText,
                source: mediaDetail.source,
                group: mediaDetail.media.group,
                filePath: mediaDetail.media.mediaDirectory,
                verified: mediaDetail.verified,
                detailId: mediaDetail.requireID()
            )
        }
        return try await detailOutput(req, repository, mediaDetail)
    }
    
    func detailOutput(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDetail: MediaDetailModel) async throws -> Media.Media.Detail {
        try await mediaDetail.$media.load(on: req.db)
        try await mediaDetail.$language.load(on: req.db)
        return try .publicDetail(
            id: repository.requireID(),
            languageCode: mediaDetail.language.languageCode,
            title: mediaDetail.title,
            detailText: mediaDetail.detailText,
            source: mediaDetail.source,
            group: mediaDetail.media.group,
            filePath: mediaDetail.media.mediaDirectory
        )
    }
    
    // MARK: - Create
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.on(.POST, body: .stream, use: createApi)
    }
    
    func createApi(_ req: Request) async throws -> Response {
        try await RequestValidator(createValidators()).validate(req)
        let input = try req.query.decode(CreateObject.self)
        let repository = DatabaseModel()
        let mediaFile = MediaFileModel()
        let mediaDetail = MediaDetailModel()
        try await createInput(req, repository, mediaDetail, mediaFile, input)
        try await create(req, repository)
        try await mediaFile.create(on: req.db)
        mediaDetail.$mediaRepository.id = try repository.requireID()
        try await mediaFile.$detailText.create(mediaDetail, on: req.db)
        return try await createResponse(req, repository, mediaDetail)
    }
    
    func beforeCreate(_ req: Request, _ model: MediaRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func createInput(_ req: Request, _ model: MediaRepositoryModel, _ input: Media.Media.Create) async throws {
        fatalError()
    }
    
    func createInput(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDetail: MediaDetailModel, _ mediaFile: MediaFileModel, _ input: Media.Media.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let waypointId = try await WaypointRepositoryModel
                .find(input.waypointId, on: req.db)?
                .requireID()
        else {
            throw Abort(.badRequest, reason: "The waypoint id is invalid")
        }
        
        guard let languageId = try await LanguageModel
                .query(on: req.db)
                .filter(\.$languageCode == input.languageCode)
                .first()?
                .requireID()
        else {
            throw Abort(.badRequest, reason: "The language code is invalid")
        }
        
        repository.$waypoint.id = waypointId
        
        // file preparations
        guard let mediaFileGroup = req.headers.contentType?.mediaGroup(), let preferredFilenameExtension = req.headers.contentType?.preferredFilenameExtension() else {
            if let fileType = req.headers.contentType {
                req.logger.log(level: .critical, "A file with the following media type could not be uploaded: \(fileType.serialize()))")
                throw Abort(.badRequest, reason: "This content type is not supportet.")
            } else {
                throw Abort(.badRequest, reason: "No media file in body")
            }
        }
        
        let mediaPath = "assets/media"
        let fileId = UUID()
        mediaFile.mediaDirectory = "\(mediaPath)/\(fileId.uuidString).\(preferredFilenameExtension)"
        mediaFile.group = mediaFileGroup
        mediaFile.$user.id = user.id
        
        // save the file
        let filePath = req.application.directory.publicDirectory + mediaFile.mediaDirectory
        try await FileStorage.saveBodyStream(of: req, to: filePath)
        
        mediaDetail.verified = false
        mediaDetail.title = input.title
        mediaDetail.detailText = input.detailText
        mediaDetail.source = input.source
        mediaDetail.$language.id = languageId
        mediaDetail.$user.id = user.id
    }
    
    func createResponse(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDetail: MediaDetailModel) async throws -> Response {
        try await detailOutput(req, repository, mediaDetail).encodeResponse(status: .created, for: req)
    }
    
    // MARK: - Update
    
    func updateApi(_ req: Request) async throws -> Response {
        try await RequestValidator(updateValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.query.decode(UpdateObject.self)
        let mediaDetail = MediaDetailModel()
        try await beforeUpdate(req, repository)
        try await updateInput(req, repository, mediaDetail, input)
        try await repository.$media.create(mediaDetail, on: req.db)
        try await afterUpdate(req, repository)
        return try await updateResponse(req, repository, mediaDetail)
    }
    
    func beforeUpdate(_ req: Request, _ model: MediaRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func updateInput(_ req: Request, _ model: MediaRepositoryModel, _ input: Media.Media.Update) async throws {
        fatalError()
    }
    
    func updateInput(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDetail: MediaDetailModel, _ input: Media.Media.Update) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        mediaDetail.verified = false
        mediaDetail.title = input.title
        mediaDetail.detailText = input.detailText
        mediaDetail.source = input.source
        mediaDetail.$language.id = languageId
        mediaDetail.$user.id = user.id
        
        if let mediaIdForFile = input.mediaIdForFile {
            guard let mediaDetailForFile = try await MediaDetailModel.find(mediaIdForFile, on: req.db) else {
                throw Abort(.badRequest)
            }
            mediaDetail.$media.id = mediaDetailForFile.$media.id
        } else {
            guard let mediaFileGroup = req.headers.contentType?.mediaGroup(), let preferredFilenameExtension = req.headers.contentType?.preferredFilenameExtension() else {
                if let fileType = req.headers.contentType {
                    req.logger.log(level: .critical, "A file with the following media type could not be uploaded: \(fileType.serialize()))")
                    throw Abort(.badRequest, reason: "This content type is not supportet.")
                } else {
                    throw Abort(.badRequest, reason: "No media file in body")
                }
            }
            
            let mediaPath = "assets/media"
            let fileId = UUID()
            let mediaFile = MediaFileModel()
            mediaFile.mediaDirectory = "\(mediaPath)/\(fileId.uuidString).\(preferredFilenameExtension)"
            mediaFile.group = mediaFileGroup
            mediaFile.$user.id = user.id
            
            // save the file
            let filePath = req.application.directory.publicDirectory + mediaFile.mediaDirectory
            try await FileStorage.saveBodyStream(of: req, to: filePath)
            try await mediaFile.create(on: req.db)
            mediaDetail.$media.id = try mediaFile.requireID()
        }
    }
    
    func updateResponse(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDetail: MediaDetailModel) async throws -> Response {
        try await detailOutput(req, repository, mediaDetail).encodeResponse(for: req)
    }
    
    // MARK: - Patch
    
    func patchApi(_ req: Request) async throws -> Response {
        try await RequestValidator(patchValidators()).validate(req)
        let repository = try await findBy(identifier(req), on: req.db)
        let input = try req.query.decode(PatchObject.self)
        try await beforePatch(req, repository)
        let mediaDetail = try await patchInputMedia(req, repository, input)
        try await afterPatch(req, repository)
        return try await patchResponse(req, repository, mediaDetail)
    }
    
    func beforePatch(_ req: Request, _ model: MediaRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func patchInput(_ req: Request, _ model: MediaRepositoryModel, _ input: Media.Media.Patch) async throws {
        fatalError()
    }
    
    // different name since otherwise it is ambiguous because of function overload with same parameters
    func patchInputMedia(_ req: Request, _ repository: MediaRepositoryModel, _ input: Media.Media.Patch) async throws -> MediaDetailModel {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let mediaToPatch = try await MediaDetailModel
            .find(input.idForMediaToPatch, on: req.db)
        else {
            throw Abort(.badRequest, reason: "No media with the given id could be found")
        }
        
        guard input.title != nil || input.detailText != nil || input.source != nil || req.headers.contentType?.mediaGroup() != nil else {
            throw Abort(.badRequest)
        }
        
        let mediaDetail = MediaDetailModel()
        
        mediaDetail.verified = false
        mediaDetail.title = input.title ?? mediaToPatch.title
        mediaDetail.detailText = input.detailText ?? mediaToPatch.detailText
        mediaDetail.source = input.source ?? mediaToPatch.source
        mediaDetail.$mediaRepository.id = try repository.requireID()
        mediaDetail.$language.id = mediaToPatch.$language.id
        mediaDetail.$user.id = user.id
        
        if let mediaFileGroup = req.headers.contentType?.mediaGroup(), let preferredFilenameExtension = req.headers.contentType?.preferredFilenameExtension() {
            let mediaPath = "assets/media"
            let fileId = UUID()
            let mediaFile = MediaFileModel()
            mediaFile.mediaDirectory = "\(mediaPath)/\(fileId.uuidString).\(preferredFilenameExtension)"
            mediaFile.group = mediaFileGroup
            mediaFile.$user.id = user.id
            
            // save the file
            let filePath = req.application.directory.publicDirectory + mediaFile.mediaDirectory
            try await FileStorage.saveBodyStream(of: req, to: filePath)
            try await mediaFile.create(on: req.db)
            mediaDetail.$media.id = try mediaFile.requireID()
        } else {
            mediaDetail.$media.id = mediaToPatch.$media.id
        }
        
        try await mediaDetail.create(on: req.db)
        return mediaDetail
    }
    
    func patchResponse(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDetail: MediaDetailModel) async throws -> Response {
        try await detailOutput(req, repository, mediaDetail).encodeResponse(for: req)
    }
    
    // MARK: - Delete
    
    func beforeDelete(_ req: Request, _ repository: MediaRepositoryModel) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require the user to be an moderator
        guard user.role >= .moderator else {
            throw Abort(.forbidden)
        }
    }
    
    func afterDelete(_ req: Request, _ repository: MediaRepositoryModel) async throws {
        try await repository.deleteDependencies(on: req.db)
    }
}
