//
//  Tagable.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol TagPivot: Fluent.Model {
    var status: Status { get set }
    var _$status: EnumProperty<Self, Status> { get }
    
    var tag: TagRepositoryModel { get set }
}

protocol Tagable: Fluent.Model {
    associatedtype Pivot: TagPivot
    
    var tags: [TagRepositoryModel] { get set }
    var _$tags: SiblingsProperty<Self, TagRepositoryModel, Pivot> { get }
}

extension Tagable where Self: RepositoryModel {
    func tagList(for languageCodesByPriority: [String], on db: Database) async throws -> [Tag.Detail.List] {
        let verifiedTags = try await _$tags
            .query(on: db)
            .filter(Pivot.self, \._$status ~~ [.verified, .deleteRequested])
            .all()
        
        return try await verifiedTags.concurrentCompactMap { tagRepository in
            guard let detail = try await tagRepository._$details.firstFor(languageCodesByPriority, needsToBeVerified: true, on: db) else {
                return nil
            }
            return try .init(id: tagRepository.requireID(), title: detail.title, slug: detail.slug)
        }
    }
    
    func tagList(_ req: Request) async throws -> [Tag.Detail.List] {
        try await tagList(for: req.allLanguageCodesByPriority(), on: req.db)
    }
}
