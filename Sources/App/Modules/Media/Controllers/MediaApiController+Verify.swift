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
        
        return try .init(
            titleDiff: titleDiff,
            detailTextDiff: detailTextDiff,
            sourceDiff: sourceDiff,
            fromGroup: model1.media.group,
            toGroup: model2.media.group,
            fromFilePath: model1.media.mediaDirectory,
            toFilePath: model2.media.mediaDirectory,
            fromUser: model1.user(),
            toUser: model2.user()
        )
    }
    
    // MARK: - list repositories with unverified details
    
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetRepositories(_ req: Request, _ queryBuilder: QueryBuilder<MediaRepositoryModel>) async throws -> QueryBuilder<MediaRepositoryModel> {
        queryBuilder
            .join(children: \._$details)
            .join(from: Detail.self, parent: \._$language)
            .join(children: \.$tags.$pivots, method: .left)
            .group(.or) { group in
                group
                    .group(.and) { group in
                        group
                        // only get unverified details
                            .filter(Detail.self, \._$verified == false)
                        // only select details which hava an active language
                            .filter(LanguageModel.self, \.$priority != nil)
                    }
                    .filter(MediaTagModel.self, \.$verified == false)
                    .filter(MediaTagModel.self, \.$deleteRequested == true)
            }
        // only select the id field and return each id only once
            .field(\._$id)
            .unique()
        
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Media.Detail.List {
        try await detail.$media.load(on: req.db)
        return try .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
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
        queryBuilder.with(\.$media)
    }
    
    // POST: api/media/:repositoryId/verify/:waypointModelId
    func verifyDetailOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Media.Detail.Detail {
        return try await .moderatorDetail(
            id: repository.requireID(),
            languageCode: detail.language.languageCode,
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            source: detail.source,
            group: detail.media.group,
            filePath: detail.media.mediaDirectory,
            tags: repository.tagList(req),
            verified: detail.verified,
            detailId: detail.requireID()
        )
    }
}
