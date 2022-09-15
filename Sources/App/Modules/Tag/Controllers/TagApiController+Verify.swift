//
//  TagApiController+Verify.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent
import SwiftDiff

extension Tag.Repository.Changes: Content { }

extension TagApiController: ApiRepositoryVerificationController {
    
    // MARK: - detail changes
    
    func beforeDetailChanges(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetDetailModel(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$user)
    }
    
    func detailChangesOutput(_ req: Request, _ model1: Detail, _ model2: Detail) async throws -> Tag.Repository.Changes {
        let titleDiff = diff(text1: model1.title, text2: model2.title).cleaningUpSemantics()
        
        let keywordDiff = model1.keywords.difference(from: model2.keywords)
        
        return try .init(
            titleDiff: titleDiff,
            equalKeywords: keywordDiff.equal,
            deletedKeywords: keywordDiff.deleted,
            insertedKeywords: keywordDiff.inserted,
            fromUser: model1.user?.publicDetail(),
            toUser: model2.user?.publicDetail()
        )
    }
    
    // MARK: - list repositories with unverified details
    
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail) async throws -> Tag.Detail.List {
        return try .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug
        )
    }
    
    // MARK: - list unverified details for repository
    
    func beforeListUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetUnverifiedDetail(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$language)
    }
    
    func listUnverifiedDetailsOutput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail) async throws -> Tag.Repository.ListUnverified {
        return try .init(
            detailId: detail.requireID(),
            title: detail.title,
            slug: detail.slug,
            keywords: detail.keywords,
            languageCode: detail.language.languageCode
        )
    }
    
    // MARK: - verify detail
    
    func beforeVerifyDetail(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func afterVerifyDetail(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail) async throws {
        if let latestVerifiedTag = try await LatestVerifiedTagModel
            .query(on: req.db)
            .filter(\.$detailId == detail.requireID())
            .first() {
            let newDocument = try latestVerifiedTag.toElasticsearch()
            let elasticResponse = try req.elastic.createOrUpdate(newDocument, id: newDocument.uniqueId, in: LatestVerifiedTagModel.Elasticsearch.schema)
            print(elasticResponse)
        }
    }
    
    func verifyDetailOutput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail) async throws -> Tag.Detail.Detail {
        return try await detailOutput(req, repository, detail)
    }
}
