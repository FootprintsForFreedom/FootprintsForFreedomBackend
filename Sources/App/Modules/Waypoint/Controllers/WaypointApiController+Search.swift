//
//  WaypointApiController+Search.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

extension WaypointApiController {
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    func searchApi(_ req: Request) async throws -> Page<Waypoint.Detail.List> {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchQuery = try req.query.decode(RepositoryDefaultSearchQuery.self)
        
        guard searchQuery.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }
        
        let pageRequest = try req.query.decode(PageRequest.self)
        
        return try await search(searchQuery, pageRequest, on: req.elastic)
            .map { .init(id: $0.id, title: $0.title, slug: $0.slug, location: .init(latitude: $0.location.lat, longitude: $0.location.lon)) }
        
    }
    
    func search(_ searchQuery: RepositoryDefaultSearchQuery, _ pageRequest: PageRequest, on elastic: ElasticHandler) async throws -> Page<ElasticModel> {
        let tags = try await TagApiController().search(searchQuery, PageRequest(page: 1, per: 100), on: elastic)
        
        var shouldQueries: [[String: Any]] = [
            [
                "multi_match": [
                    "query": searchQuery.text,
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
        
        do {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(ElasticModel.schema(for: searchQuery.languageCode))/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData)
            
            return Page(
                items: response.hits.hits.map(\.source),
                metadata: PageMetadata(page: pageRequest.page, per: pageRequest.per, total: response.hits.total.value)
            )
        } catch let error as ElasticSearchClientError {
            guard let status = error.status else { throw Abort(.internalServerError) }
            throw Abort(status)
        } catch {
            throw Abort(.internalServerError)
        }
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
    
    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
        baseRoutes.get("in", use: getInCoordinatesApi)
    }
}
