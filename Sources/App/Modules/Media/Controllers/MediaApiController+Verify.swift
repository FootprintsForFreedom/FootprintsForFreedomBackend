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

extension MediaApiController: ApiRepositoryVerificationController {
    
    // MARK: - detail changes
    
    func beforeDetailChanges(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$user).with(\.$media)
    }
    
    // GET: api/media/:mediaId/changes/?from=modelId1&to=modelId2
    func detailChangesOutput(_ req: Request, _ model1: Detail, _ model2: Detail) async throws -> Media.Repository.Changes {
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
    
    // MARK: - list repositories with unverified details
    
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Media.Detail.List {
        try await detail.$media.load(on: req.db)
        return try .init(
            id: repository.requireID(),
            title: detail.title,
            group: detail.media.group
        )
    }
    
    // MARK: - list unverified details for repository
    
    func beforeListUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetUnverifiedDetail(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$language)
    }
    
    func listUnverifiedDetailsOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Media.Repository.ListUnverified {
        return try .init(
            modelId: detail.requireID(),
            title: detail.title,
            detailText: detail.detailText,
            languageCode: detail.language.languageCode
        )
    }
    
    // MARK: - verify detail
    
    func beforeVerifyDetail(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetDetailToVerify(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$language).with(\.$media)
    }
    
    // POST: api/media/:repositoryId/verify/:waypointModelId
    func verifyDetailOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Media.Detail.Detail {
        return try .moderatorDetail(
            id: repository.requireID(),
            languageCode: detail.language.languageCode,
            title: detail.title,
            detailText: detail.detailText,
            source: detail.source,
            group: detail.media.group,
            filePath: detail.media.mediaDirectory,
            verified: detail.verified, // TODO: && media.file.verififed
            detailId: detail.requireID()
        )
    }
}
