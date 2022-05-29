//
//  TagApiController+Verify.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent
import DiffMatchPatch

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
        let titleDiff = computeDiff(model1.title, model2.title)
            .cleaningUpSemantics()
            .converted()
        
        let keywordDiff = model1.keywords.difference(from: model2.keywords)
        
        let model1User = try User.Account.Detail.publicDetail(id: model1.user.requireID(), name: model1.user.name, school: model1.user.school)
        let model2User = try User.Account.Detail.publicDetail(id: model2.user.requireID(), name: model2.user.name, school: model2.user.school)
        
        return .init(
            titleDiff: titleDiff,
            equalKeywords: keywordDiff.equal,
            deletedKeywords: keywordDiff.deleted,
            insertedKeywords: keywordDiff.inserted,
            fromUser: model1User,
            toUser: model2User
        )
    }
    
    // MARK: - list repositories with unverified details
    
    func beforeListRepositoriesWithUnverifiedDetails(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func listRepositoriesWithUnverifiedDetailsOutput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail) async throws -> Tag.Detail.List {
        return try .init(
            id: repository.requireID(),
            title: detail.title
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
            modelId: detail.requireID(),
            title: detail.title,
            keywords: detail.keywords,
            languageCode: detail.language.languageCode
        )
    }
    
    // MARK: - verify detail
    
    func beforeVerifyDetail(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func beforeGetDetailToVerify(_ req: Request, _ queryBuilder: QueryBuilder<Detail>) async throws -> QueryBuilder<Detail> {
        queryBuilder.with(\.$language)
    }
    
    func verifyDetailOutput(_ req: Request, _ repository: TagRepositoryModel, _ detail: Detail) async throws -> Tag.Detail.Detail {
        return try .moderatorDetail(
            id: repository.requireID(),
            title: detail.title,
            keywords: detail.keywords,
            languageCode: detail.language.languageCode,
            verified: detail.verified,
            detailId: detail.requireID()
        )
    }
}