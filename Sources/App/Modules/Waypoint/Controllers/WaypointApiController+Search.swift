//
//  WaypointApiController+Search.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Vapor
import Fluent

extension WaypointApiController: ApiElasticSearchController {
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func getInCoordinatesValidators() -> [AsyncValidator] {
        KeyedContentValidator<Double>.required("tepLeftLatitude")
        KeyedContentValidator<Double>.required("tepLeftLongitude")
        KeyedContentValidator<Double>.required("bottomRightLatitude")
        KeyedContentValidator<Double>.required("bottomRightLongitude")
    }
    
    // MARK: - Routes
    
    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
        baseRoutes.get("suggest", use: suggestApi)
        baseRoutes.get("in", use: getInCoordinatesApi)
    }
    
    // MARK: - Search
    
    func searchQuery(_ searchContext: RepositoryDefaultSearchContext, _ pageRequest: PageRequest, on elastic: ElasticHandler) async throws -> [String : Any] {
        let tags = try await TagApiController().search(searchContext, PageRequest(page: 1, per: 100), on: elastic)
        
        var shouldQueries: [[String: Any]] = [
            [
                "multi_match": [
                    "query": searchContext.text,
                    "fields": ["title", "detailText"]
                ]
            ]
        ]
        
        let tagTermQueries: [[String: Any]] = tags.items.map {
            [
                "term": [
                    "tags": [
                        "value": $0.id.uuidString
                    ]
                ]
            ]
        }
        shouldQueries.append(contentsOf: tagTermQueries)
        
        let query: [String: Any] = [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "query": [
                "bool": [
                    "should": shouldQueries
                ]
            ]
        ]
        
        return query
    }
    
    func searchOutput(_ req: Request, _ model: WaypointSummaryModel.Elasticsearch) async throws -> Waypoint.Detail.List {
        .init(id: model.id, title: model.title, slug: model.slug, location: .init(latitude: model.location.lat, longitude: model.location.lon))
    }
    
    // MARK: - Get in Range
    
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
            .filter(\.$verifiedAt != nil)
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
}
