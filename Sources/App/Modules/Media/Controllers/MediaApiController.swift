//
//  MediaApiController.swift
//
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent
import AppApi

extension Media.Detail.List: Content { }
extension Media.Detail.Detail: Content { }

//struct MediaApiController: ApiRepositoryController {
struct MediaApiController: ApiElasticDetailController, ApiElasticPagedListController, ApiRepositoryCreateController, ApiRepositoryUpdateController, ApiRepositoryPatchController, ApiDeleteController {
    typealias ApiModel = Media.Detail
    typealias DatabaseModel = MediaRepositoryModel
    typealias ElasticModel = MediaSummaryModel.Elasticsearch
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func createValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("detailText")
        KeyedContentValidator<String>.required("source")
        KeyedContentValidator<String>.required("languageCode")
        KeyedContentValidator<UUID>.required("waypointId")
    }
    
    @AsyncValidatorBuilder
    func updateValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("detailText")
        KeyedContentValidator<String>.required("source")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func patchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: true)
        KeyedContentValidator<String>.required("detailText", optional: true)
        KeyedContentValidator<String>.required("source", optional: true)
        KeyedContentValidator<UUID>.required("idForMediaDetailToPatch")
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
    
    func listOutput(_ req: Request, _ model: MediaSummaryModel.Elasticsearch) -> Media.Detail.List {
        return .init(
            id: model.id,
            title: model.title,
            slug: model.slug,
            group: model.group,
            // TODO: actual thumbnail file path!!!
            thumbnailFilePath: model.relativeMediaFilePath
        )
    }
    
//    func listOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: MediaDetailModel) async throws -> Media.Detail.List {
//        // TODO: is this a bottleneck for the time it takes to return a result?
//        try await detail.$media.load(on: req.db)
//        return .init(
//            id: try repository.requireID(),
//            title: detail.title,
//            slug: detail.slug,
//            group: detail.media.group,
//            thumbnailFilePath: detail.media.relativeThumbnailFilePath
//        )
//    }
    
    // MARK: - Detail
    
    func detailOutput(_ req: Request, _ model: MediaSummaryModel.Elasticsearch, _ availableLanguageCodes: [String]) async throws -> Media.Detail.Detail {
        let tagList = try await model.getTagList(preferredLanguageCode: req.preferredLanguageCode(), on: req.elastic) // TODO: we get the preferred language code twice...
        return .init(
            id: model.id,
            languageCode: model.languageCode,
            availableLanguageCodes: availableLanguageCodes,
            title: model.title,
            slug: model.slug,
            detailText: model.detailText,
            source: model.source,
            group: model.group,
            filePath: model.relativeMediaFilePath,
            tags: tagList,
            detailId: model.detailId
        )
    }
    
    func detailOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: MediaDetailModel) async throws -> Media.Detail.Detail {
        try await detail.$media.load(on: req.db)
        try await detail.$language.load(on: req.db)

        return try await .init(
            id: repository.requireID(),
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(req.db),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            source: detail.source,
            group: detail.media.group,
            filePath: detail.media.relativeMediaFilePath,
            tags: repository.tagList(req),
            detailId: detail.requireID()
        )
    }
    
    // MARK: - Create
    
    func setupCreateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.on(.POST, body: .stream, use: createApi)
    }
    
    func beforeCreate(_ req: Request, _ model: MediaRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func getCreateInput(_ req: Request) async throws -> Media.Detail.Create {
        try await RequestValidator(createValidators()).validate(req, .query)
        return try req.query.decode(CreateObject.self)
    }
    
    func createRepositoryInput(_ req: Request, _ repository: MediaRepositoryModel, _ input: Media.Detail.Create) async throws {
        guard let waypointId = try await WaypointRepositoryModel
            .find(input.waypointId, on: req.db)?
            .requireID()
        else {
            throw Abort(.badRequest, reason: "The waypoint id is invalid")
        }
        
        repository.$waypoint.id = waypointId
    }
    
    func createInput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: MediaDetailModel, _ input: Media.Detail.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$priority != nil)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest, reason: "The language code is invalid")
        }
        
        // file preparations
        guard let mediaFileGroup = req.headers.contentType?.mediaGroup(), let preferredFilenameExtension = req.headers.contentType?.preferredFilenameExtension() else {
            if let fileType = req.headers.contentType {
                req.logger.log(level: .critical, "A file with the following media type could not be uploaded: \(fileType.serialize()))")
                throw Abort(.unsupportedMediaType, reason: "This content type is not supported.")
            } else {
                throw Abort(.badRequest, reason: "No media file in body")
            }
        }
        
        let mediaFile = MediaFileModel()
        
        let mediaPath = "assets/media"
        let fileId = UUID()
        mediaFile.relativeMediaFilePath = "\(mediaPath)/\(fileId.uuidString).\(preferredFilenameExtension)"
        mediaFile.group = mediaFileGroup
        mediaFile.$user.id = user.id
        
        // save the file
        try await FileStorage.saveBodyStream(of: req, to: mediaFile.absoluteMediaFilePath(req))
        try await mediaFile.create(on: req.db)
        try await mediaFile.createThumbnail(req: req)
        
        detail.$media.id = try mediaFile.requireID()
        detail.title = input.title
        detail.detailText = input.detailText
        detail.source = input.source
        detail.$language.id = languageId
        detail.$user.id = user.id
    }
    
    func createResponse(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(status: .created, for: req)
    }
    
    // MARK: - Update
    
    func setupUpdateRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.on(.PUT, body: .stream, use: updateApi)
    }
    
    func beforeUpdate(_ req: Request, _ model: MediaRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func getUpdateInput(_ req: Request) async throws -> Media.Detail.Update {
        try await RequestValidator(updateValidators()).validate(req, .query)
        return try req.query.decode(UpdateObject.self)
    }
    
    func updateInput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: MediaDetailModel, _ input: Media.Detail.Update) async throws {
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
        
        detail.title = input.title
        detail.detailText = input.detailText
        detail.source = input.source
        detail.$language.id = languageId
        detail.$user.id = user.id
        
        if let mediaIdForFile = input.mediaIdForFile {
            guard let detailForFile = try await MediaDetailModel.find(mediaIdForFile, on: req.db) else {
                throw Abort(.badRequest)
            }
            detail.$media.id = detailForFile.$media.id
        } else {
            guard let mediaFileGroup = req.headers.contentType?.mediaGroup(), let preferredFilenameExtension = req.headers.contentType?.preferredFilenameExtension() else {
                if let fileType = req.headers.contentType {
                    req.logger.log(level: .critical, "A file with the following media type could not be uploaded: \(fileType.serialize()))")
                    throw Abort(.unsupportedMediaType, reason: "This content type is not supported.")
                } else {
                    throw Abort(.badRequest, reason: "No media file in body")
                }
            }
            
            let mediaPath = "assets/media"
            let fileId = UUID()
            let mediaFile = MediaFileModel()
            mediaFile.relativeMediaFilePath = "\(mediaPath)/\(fileId.uuidString).\(preferredFilenameExtension)"
            mediaFile.group = mediaFileGroup
            mediaFile.$user.id = user.id
            
            // save the file
            try await FileStorage.saveBodyStream(of: req, to: mediaFile.absoluteMediaFilePath(req))
            try await mediaFile.create(on: req.db)
            try await mediaFile.createThumbnail(req: req)
            detail.$media.id = try mediaFile.requireID()
        }
    }
    
    func updateResponse(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }
    
    // MARK: - Patch
    
    func setupPatchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.on(.PATCH, body: .stream, use: patchApi)
    }
    
    func beforePatch(_ req: Request, _ model: MediaRepositoryModel) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func getPatchInput(_ req: Request) async throws -> Media.Detail.Patch {
        try await RequestValidator(patchValidators()).validate(req, .query)
        return try req.query.decode(PatchObject.self)
    }
    
    func patchInput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: MediaDetailModel, _ input: Media.Detail.Patch) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let mediaToPatch = try await MediaDetailModel.find(input.idForMediaDetailToPatch, on: req.db) else {
            throw Abort(.badRequest, reason: "No media with the given id could be found")
        }
        
        guard input.title != nil || input.detailText != nil || input.source != nil || req.headers.contentType?.mediaGroup() != nil else {
            throw Abort(.badRequest)
        }
        
        detail.title = input.title ?? mediaToPatch.title
        detail.detailText = input.detailText ?? mediaToPatch.detailText
        detail.source = input.source ?? mediaToPatch.source
        detail.$repository.id = try repository.requireID()
        detail.$language.id = mediaToPatch.$language.id
        detail.$user.id = user.id
        
        if let mediaFileGroup = req.headers.contentType?.mediaGroup(), let preferredFilenameExtension = req.headers.contentType?.preferredFilenameExtension() {
            let mediaPath = "assets/media"
            let fileId = UUID()
            let mediaFile = MediaFileModel()
            mediaFile.relativeMediaFilePath = "\(mediaPath)/\(fileId.uuidString).\(preferredFilenameExtension)"
            mediaFile.group = mediaFileGroup
            mediaFile.$user.id = user.id
            
            // save the file
            try await FileStorage.saveBodyStream(of: req, to: mediaFile.absoluteMediaFilePath(req))
            try await mediaFile.create(on: req.db)
            try await mediaFile.createThumbnail(req: req)
            detail.$media.id = try mediaFile.requireID()
        } else {
            detail.$media.id = mediaToPatch.$media.id
        }
    }
    
    func patchResponse(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Response {
        try await detailOutput(req, repository, detail).encodeResponse(for: req)
    }
    
    // MARK: - Delete
    
    func beforeDelete(_ req: Request, _ repository: MediaRepositoryModel) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func afterDelete(_ req: Request, _ repository: MediaRepositoryModel) async throws {
        try await MediaSummaryModel.Elasticsearch.delete(allDetailsWithRepositoryId: repository.requireID(), on: req)
    }
}
