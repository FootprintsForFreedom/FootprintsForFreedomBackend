//
//  MediaApiController.swift
//
//
//  Created by niklhut on 09.05.22.
//

import Vapor
import Fluent
import Liquid

extension Media.Media.List: Content { }
extension Media.Media.Detail: Content { }

struct MediaApiController: ApiController {
    typealias ApiModel = Media.Media
    typealias DatabaseModel = MediaRepositoryModel
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title", optional: optional, validateQuery: true)
        KeyedContentValidator<String>.required("description", optional: optional, validateQuery: true)
        KeyedContentValidator<String>.required("source", optional: optional, validateQuery: true)
        // TODO: Attention when update and patch
        KeyedContentValidator<UUID>.required("waypointId", optional: optional, validateQuery: true)
        KeyedContentValidator<String>.required("languageCode", optional: optional, validateQuery: true)
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
    
    func onlyForVerifiedUser(_ req: Request) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a admin or higher
        guard user.verified else {
            throw Abort(.forbidden)
        }
    }
    
    // MARK: - List
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<MediaRepositoryModel>) async throws -> QueryBuilder<MediaRepositoryModel> {
        queryBuilder
        // only return repositories with verified media descriptions inside
            .join(MediaDescriptionModel.self, on: \MediaDescriptionModel.$mediaRepository.$id == \MediaRepositoryModel.$id)
            .filter(MediaDescriptionModel.self, \.$verified == true)
        // only return media descriptions which have a activated language
            .join(LanguageModel.self, on: \MediaDescriptionModel.$language.$id == \LanguageModel.$id)
            .filter(LanguageModel.self, \.$priority != nil)
            .field(\.$id)
            .unique()
    }
    
    func listOutput(_ req: Request, _ models: Page<MediaRepositoryModel>) async throws -> Page<Media.Media.List> {
        // TODO: sort?
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        return try await models
            .concurrentMap { model in
                if let mediaDescription = try await model.media(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db) {
                    // TODO: is this a bottleneck for the time it takes to return a result?
                    try await mediaDescription.$media.load(on: req.db)
                    return .init(
                        id: try model.requireID(),
                        title: mediaDescription.title,
                        group: mediaDescription.media.group
                    )
                } else {
                    return nil
                }
            }
            .compactMap { $0 }
    }
    
    // MARK: - Detail
    
    func detailOutput(_ req: Request, _ repository: MediaRepositoryModel) async throws -> Media.Media.Detail {
        let preferredLanguageCode = try req.query.decode(PreferredLanguageQuery.self).preferredLanguage
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: preferredLanguageCode, on: req.db)
        
        guard let mediaDescription = try await repository.media(for: allLanguageCodesByPriority, needsToBeVerified: true, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db), user.role >= .moderator {
            try await mediaDescription.$media.load(on: req.db)
            try await mediaDescription.$language.load(on: req.db)
            
            return try .moderatorDetail(
                id: repository.requireID(),
                languageCode: mediaDescription.language.languageCode,
                title: mediaDescription.title,
                description: mediaDescription.description,
                source: mediaDescription.source,
                group: mediaDescription.media.group,
                filePath: mediaDescription.media.mediaDirectory,
                verified: mediaDescription.verified
            )
        }
        return try await detailOutput(req, repository, mediaDescription)
    }
    
    func detailOutput(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDescription: MediaDescriptionModel) async throws -> Media.Media.Detail {
        try await mediaDescription.$media.load(on: req.db)
        try await mediaDescription.$language.load(on: req.db)
        return try .publicDetail(
            id: repository.requireID(),
            languageCode: mediaDescription.language.languageCode,
            title: mediaDescription.title,
            description: mediaDescription.description,
            source: mediaDescription.source,
            group: mediaDescription.media.group,
            filePath: mediaDescription.media.mediaDirectory
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
        let mediaDescription = MediaDescriptionModel()
        try await createInput(req, repository, mediaDescription, mediaFile, input)
        try await create(req, repository)
        try await mediaFile.create(on: req.db)
        mediaDescription.$mediaRepository.id = try repository.requireID()
        try await mediaFile.$descriptions.create(mediaDescription, on: req.db)
        return try await createResponse(req, repository, mediaDescription)
    }
    
    // not implemented, instead function below is used, however this function is required by the protocol
    func createInput(_ req: Request, _ model: MediaRepositoryModel, _ input: Media.Media.Create) async throws {
        fatalError()
    }
    
    func createInput(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDescription: MediaDescriptionModel, _ mediaFile: MediaFileModel, _ input: Media.Media.Create) async throws {
        let user = try req.auth.require(AuthenticatedUser.self)
        
        // TODO: verify waypointID
        repository.$waypoint.id = input.waypointId
        
        guard let languageId = try await LanguageModel
            .query(on: req.db)
            .filter(\.$languageCode == input.languageCode)
            .first()?
            .requireID()
        else {
            throw Abort(.badRequest)
        }
        
        // file preparations
        guard let fileType = req.headers.contentType, let group = Media.Media.Group.for("\(fileType.type)/\(fileType.subType)"), let preferredFilenameExtension = Media.Media.Group.preferredFilenameExtension(for: "\(fileType.type)/\(fileType.subType)") else {
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
        mediaFile.group = group
        mediaFile.$user.id = user.id
        
        // save the file
        let filePath = req.application.directory.publicDirectory + mediaFile.mediaDirectory
        
        var sequential = req.eventLoop.makeSucceededFuture(())
        try await req.application.fileio.openFile(path: filePath, mode: .write, flags: .allowFileCreation(), eventLoop: req.eventLoop)
            .flatMap { handle -> EventLoopFuture<Void> in
                let promise = req.eventLoop.makePromise(of: Void.self)
                
                req.body.drain {
                    switch $0 {
                    case .buffer(let chunk):
                        sequential = sequential.flatMap {
                            req.application.fileio.write(fileHandle: handle, buffer: chunk, eventLoop: req.eventLoop)
                        }
                        return sequential
                    case .error(let error):
                        promise.fail(error)
                        return req.eventLoop.makeSucceededFuture(())
                    case .end:
                        promise.succeed(())
                        return req.eventLoop.makeSucceededFuture(())
                    }
                }
                
                return promise.futureResult
                    .flatMap {
                        sequential
                    }
                    .always { result in
                        _ = try? handle.close()
                    }
            }
            .get()
                
        mediaDescription.verified = false
        mediaDescription.title = input.title
        mediaDescription.description = input.description
        mediaDescription.source = input.source
        mediaDescription.$language.id = languageId
        mediaDescription.$user.id = user.id
    }
    
    func createResponse(_ req: Request, _ repository: MediaRepositoryModel, _ mediaDescription: MediaDescriptionModel) async throws -> Response {
        try await detailOutput(req, repository, mediaDescription).encodeResponse(status: .created, for: req)
    }
    
    // MARK: - Update
    
    func updateInput(_ req: Request, _ model: MediaRepositoryModel, _ input: Media.Media.Update) async throws {
        print("hello")
    }
    
    // MARK: - Patch
    
    func patchInput(_ req: Request, _ model: MediaRepositoryModel, _ input: Media.Media.Patch) async throws {
        print("hello")
    }
    
    // MARK: - Delete
    
}
