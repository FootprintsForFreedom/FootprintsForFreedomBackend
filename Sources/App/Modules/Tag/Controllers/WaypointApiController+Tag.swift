//
//  WaypointApiController+Tag.swift
//  
//
//  Created by niklhut on 30.05.22.
//

import Vapor
import Fluent

extension Waypoint.Repository.ListUnverifiedTags: Content { }

extension WaypointApiController {
    var tagPathIdKey: String { "tag" }
    var tagPathIdComponent: PathComponent { .init(stringLiteral: ":" + tagPathIdKey) }
    
    private func getTagId(_ req: Request) throws -> UUID {
        guard
            let tagIdString = req.parameters.get(tagPathIdKey),
            let tagId = UUID(uuidString: tagIdString)
        else {
            throw Abort(.badRequest)
        }
        return tagId
    }
    
    private func getRepositoryWithDetails(_ req: Request) async throws -> (repository: WaypointRepositoryModel, detail: WaypointDetailModel, location: WaypointLocationModel) {
        let repository = try await repository(req)
        guard
            let detail = try await repository.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: false, on: req.db),
            let location = try await repository.location(needsToBeVerified: false, on: req.db)
        else {
            throw Abort(.badRequest)
        }
        
        return (repository, detail, location)
    }
    
    // MARK: - Routes
    
    func setupTagRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        let tagRoutes = existingModelRoutes.grouped("tags")
        
        tagRoutes.get("unverified", use: listUnverifiedTags)
        
        let newTagRoutes = tagRoutes.grouped(tagPathIdComponent)
        
        newTagRoutes.post(use: addTag)
        newTagRoutes.delete(use: requestRemoveTag)
        
        let verifyTagRoutes = tagRoutes
            .grouped("verify")
            .grouped(tagPathIdComponent)
        
        verifyTagRoutes.post(use: verifyAddedTag)
        verifyTagRoutes.delete(use: removeTag)
    }
    
    // MARK: - add tag
    
    func addTag(_ req: Request) async throws -> Waypoint.Detail.Detail {
        try await req.onlyForVerifiedUser()
        let (repository, detail, location) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)
        
        guard
            let tag = try await TagRepositoryModel.find(tagId, on: req.db),
            try await tag.containsVerifiedDetail(req.db)
        else {
            throw Abort(.badRequest, reason: "The tag needs to be verified")
        }
        
        try await repository.$tags.attach(tag, method: .ifNotExists, on: req.db)
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    func verifyAddedTag(_ req: Request) async throws -> Waypoint.Detail.Detail {
        try await req.onlyFor(.moderator)
        let (repository, detail, location) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)
        
        guard
            let tagPivot = try await repository.$tags.$pivots.query(on: req.db)
                .filter(\.$waypoint.$id == repository.requireID())
                .filter(\.$tag.$id == tagId)
                .first(),
            tagPivot.verified == false
        else {
            throw Abort(.badRequest)
        }
        
        tagPivot.verified = true
        try await tagPivot.save(on: req.db)
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    // MARK: - remove tag
    
    func requestRemoveTag(_ req: Request) async throws -> Waypoint.Detail.Detail {
        try await req.onlyForVerifiedUser()
        let (repository, detail, location) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)
        
        guard
            let tagPivot = try await repository.$tags.$pivots.query(on: req.db)
                .filter(\.$waypoint.$id == repository.requireID())
                .filter(\.$tag.$id == tagId)
                .first()
        else {
            throw Abort(.badRequest)
        }
        
        tagPivot.deleteRequested = true
        try await tagPivot.save(on: req.db)
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    func removeTag(_ req: Request) async throws -> Waypoint.Detail.Detail {
        try await req.onlyFor(.moderator)
        let (repository, detail, location) = try await getRepositoryWithDetails(req)
        let tagId = try getTagId(req)
        
        guard let tag = try await TagRepositoryModel.find(tagId, on: req.db) else {
            throw Abort(.badRequest)
        }
        
        try await repository.$tags.detach(tag, on: req.db)
        
        return try await detailOutput(req, repository, detail, location)
    }
    
    // MARK: list unverified tags
    
    func listUnverifiedTags(_ req: Request) async throws -> [Waypoint.Repository.ListUnverifiedTags] {
        try await req.onlyFor(.moderator)
        let repository = try await repository(req)
        
        let unverifiedTags = try await repository.$tags.$pivots
            .query(on: req.db)
            .group(.or) { group in
                group.filter(\.$verified == false)
                    .filter(\.$deleteRequested == true)
            }
            .all()
        
        return try await unverifiedTags.concurrentMap { tag in
            try await tag.$tag.load(on: req.db)
            guard let detail = try await tag.tag.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: false, on: req.db) else {
                throw Abort(.internalServerError)
            }
            return try .init(
                tagId: tag.tag.requireID(),
                title: detail.title,
                changeAction: tag.verified == false ? .verify : .delete
            )
        }
    }
}
