//
//  WaypointApiController+Search.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Vapor
import Fluent

extension WaypointApiController {
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    struct SearchQuery: Codable {
        let text: String
        let languageCode: String
    }
    
    func searchApi(_ req: Request) async throws -> Page<Waypoint.Detail.List> {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchQuery = try req.query.decode(SearchQuery.self)
        
        guard searchQuery.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }
        let searchText = searchQuery.text.lowercased()
        
        let allDetails = try await WaypointDetailModel
            .query(on: req.db)
        // only search verified details
            .filter(\.$status ~~ [.verified, .deleteRequested])
            .join(parent: \.$language)
        // only search details with given language
            .filter(LanguageModel.self, \.$languageCode == searchQuery.languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        // get all verified details for the repository in the specified language
            .all()
        
        let newestDetailsForRepositories = try allDetails
        // group the details by repository id
            .grouped(by: \.$repository.id)
        // get the newest detail for each repository
            .map { $1.sorted { $0.updatedAt! > $1.updatedAt! }.first! }
        // load the tag for all remaining details
        
        var detailInLanguageForTagRepository = [TagRepositoryModel.IDValue: TagDetailModel]()
        
        let filteredDetails = try await newestDetailsForRepositories
            .concurrentMap { waypointDetail -> (WaypointDetailModel, [TagDetailModel]) in
                let tagRepositoryIds = try await WaypointTagModel.query(on: req.db)
                    .filter(\.$waypoint.$id == waypointDetail.$repository.id)
                    .field(\.$tag.$id)
                    .unique()
                    .all()
                    .map(\.$tag.id)
                
                let tagDetails = try await tagRepositoryIds
                    .concurrentCompactMap { repositoryId -> TagDetailModel? in
                        if let detail = detailInLanguageForTagRepository[repositoryId] {
                            return detail
                        } else {
                            guard let detail = try await TagDetailModel
                                .query(on: req.db)
                                .join(parent: \.$language)
                                .filter(LanguageModel.self, \.$languageCode == searchQuery.languageCode)
                                .filter(\.$repository.$id == repositoryId)
                                .filter(\.$status ~~ [.verified, .deleteRequested])
                                .sort(\.$updatedAt, .descending) // newest first
                                .first()
                            else {
                                return nil
                            }
                            detailInLanguageForTagRepository[repositoryId] = detail
                            return detail
                        }
                    }
                
                return (waypointDetail, tagDetails)
            }
            .filter { waypointDetail, tagDetails in
                return waypointDetail.title.lowercased().contains(searchText) ||
                waypointDetail.detailText.lowercased().contains(searchText) ||
                tagDetails.contains { $0.title.lowercased().contains(searchText) } ||
                tagDetails.contains { $0.keywords.contains { $0.lowercased().contains(searchText) } }
            }
            .concurrentCompactMap { (detail, tagDetails) -> (waypoint: WaypointDetailModel, location: WaypointLocationModel)? in
                guard let location = try await WaypointLocationModel.firstFor(detail.$repository.id, needsToBeVerified: true, on: req.db) else {
                    return nil
                }
                return (detail, location)
            }
        
        let count = filteredDetails.count
        let page = try req.query.decode(PageRequest.self)
        
        let relevantDetails = filteredDetails.dropFirst((page.page - 1) * page.per).prefix(page.per)
        
        return Page(
            items: relevantDetails.map { detail, location in
                return .init(id: detail.$repository.id, title: detail.title, slug: detail.slug, location: location.location)
            },
            metadata: PageMetadata(page: page.page, per: page.per, total: count)
        )
    }
    
    @AsyncValidatorBuilder
    func getInCoordinatesValidators() -> [AsyncValidator] {
        KeyedContentValidator<Double>.required("tepLeftLatitude")
        KeyedContentValidator<Double>.required("tepLeftLongitude")
        KeyedContentValidator<Double>.required("bottomRightLatitude")
        KeyedContentValidator<Double>.required("bottomRightLongitude")
    }
    
    struct GetInRangeQuery: Codable {
        let tepLeftLatitude: Double
        let tepLeftLongitude: Double
        let bottomRightLatitude: Double
        let bottomRightLongitude: Double
    }
    
    func getInCoordinatesApi(_ req: Request) async throws -> [Waypoint.Detail.List] {
        try await RequestValidator(getInCoordinatesValidators()).validate(req, .query)
        let getInRangeQuery = try req.query.decode(GetInRangeQuery.self)
        
        // filters all locations - also those that are no longer the newest ones
        // this might lead to a few more waypoints in the results but should still be more performant than further in memory processing
        let repositoryIds = try await WaypointLocationModel
            .query(on: req.db)
            .filter(\.$status ~~ [.verified, .deleteRequested])
            .filter(\.$latitude <= getInRangeQuery.tepLeftLatitude)
            .filter(\.$latitude >= getInRangeQuery.bottomRightLatitude)
            .filter(\.$longitude <= getInRangeQuery.tepLeftLongitude)
            .filter(\.$longitude >= getInRangeQuery.bottomRightLongitude)
            .field(\.$repository.$id)
            .unique()
            .all()
            .map(\.$repository.id)
        
        
        return try await repositoryIds.concurrentCompactMap { repositoryId in
            guard
                let repository = try await WaypointRepositoryModel.find(repositoryId, on: req.db),
                let detail = try await repository._$details.firstFor(req.allLanguageCodesByPriority(), needsToBeVerified: true, on: req.db),
                let location = try await repository.$locations.firstFor(needsToBeVerified: true, on: req.db)
            else {
                return nil
            }
            return .init(
                id: repositoryId,
                title: detail.title,
                slug: detail.slug,
                location: location.location
            )
        }
    }
    
    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
        baseRoutes.get("in", use: getInCoordinatesApi)
    }
}
