//
//  MediaApiController+Verify.swift
//  
//
//  Created by niklhut on 17.05.22.
//

import Vapor
import Fluent
import AppApi
import SwiftDiff

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
        let titleDiff = diff(text1: model1.title, text2: model2.title).cleaningUpSemantics()
        let detailTextDiff = diff(text1: model1.detailText, text2: model2.detailText).cleaningUpSemantics()
        let sourceDiff = diff(text1: model1.source, text2: model2.source).cleaningUpSemantics()
        
        return try .init(
            titleDiff: titleDiff,
            detailTextDiff: detailTextDiff,
            sourceDiff: sourceDiff,
            fromFilePath: model1.media.relativeMediaFilePath,
            toFilePath: model2.media.relativeMediaFilePath,
            fromUser: model1.user?.publicDetail(),
            toUser: model2.user?.publicDetail()
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
                            .filter(Detail.self, \.$verifiedAt == nil)
                        // only select details which have an active language
                            .filter(LanguageModel.self, \.$priority != nil)
                    }
                    .filter(MediaTagModel.self,\.$status ~~ [.pending, .deleteRequested])
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
            fileType: detail.media.fileType,
            thumbnailFilePath: detail.media.relativeThumbnailFilePath
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
            detailId: detail.requireID(),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            languageCode: detail.language.languageCode
        )
    }
    
    // MARK: - verify detail
    
    func beforeVerifyDetail(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func afterVerifyDetail(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws {
        try await MediaSummaryModel.Elasticsearch.createOrUpdate(detailWithId: detail.requireID(), on: req)
    }
    
    // POST: api/media/:repositoryId/verify/:waypointModelId
    func verifyDetailOutput(_ req: Request, _ repository: MediaRepositoryModel, _ detail: Detail) async throws -> Media.Detail.Detail {
        return try await detailOutput(req, repository, detail)
    }
}
