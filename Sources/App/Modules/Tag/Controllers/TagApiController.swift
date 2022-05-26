//
//  TagApiController.swift
//  
//
//  Created by niklhut on 21.05.22.
//

import Vapor
import Fluent

//struct TagApiController: ApiController {
//    typealias ApiModel = Tag.Detail
//    typealias DatabaseModel = TagRepositoryModel
//    
//    // MARK: - Validators
//    
//    
//    
//    // MARK: - Routes
//    
//    func getBaseRoutes(_ routes: RoutesBuilder) -> RoutesBuilder {
//        routes.grouped("tags")
//    }
//    
//    func setupRoutes(_ routes: RoutesBuilder) {
//        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
//        setupListRoutes(routes)
//        setupDetailRoutes(routes)
//        setupCreateRoutes(protectedRoutes)
//        setupUpdateRoutes(protectedRoutes)
//        setupPatchRoutes(protectedRoutes)
//        setupDeleteRoutes(protectedRoutes)
//    }
//    
//    // MARK: - List
//    
//    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<TagRepositoryModel>) async throws -> QueryBuilder<TagRepositoryModel> {
//        queryBuilder
//            // only return repositories with verified details insid
//            .join(TagDetailModel.self, on: \TagDetailModel.$repository.$id == \TagRepositoryModel.$id)
//            .filter(TagDetailModel.self, \.$verified == true)
//        // only return details which have a activated language
//            .join(LanguageModel.self, on: \TagDetailModel.$language.$id == \LanguageModel.$id)
//            .filter(LanguageModel.self, \.$priority != nil)
//            .field(\.$id)
//            .unique()
//    }
//    
//    func listOutput(_ req: Request, _ models: Page<TagRepositoryModel>) async throws -> Page<Tag.Detail.List> {
//        // TODO: sort?
//        return try await models
//            .concurrentMap { model in
//                guard let detail = try await model.detail(for: req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db) else {
//                    return nil
//                }
//                
//                return try .init(
//                    id: detail.requireID(),
//                    title: detail.title
//                )
//            }
//            .compactMap { $0 }
//    }
//    
//    // MARK: - Detail
//    
//    
//}
