//
//  WaypointApiController+Search.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Vapor
import Fluent
import AppApi
import ElasticsearchNIOClient

extension WaypointApiController: ApiElasticSearchController {
    
    // MARK: - Validators
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    @AsyncValidatorBuilder
    func getInCoordinatesValidators() -> [AsyncValidator] {
        KeyedContentValidator<Double>.required("topLeftLatitude")
        KeyedContentValidator<Double>.required("topLeftLongitude")
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
        listOutput(req, model)
    }
    
    // MARK: - Get in Range
    
    func getInCoordinatesApi(_ req: Request) async throws -> AppApi.Page<Waypoint.Detail.List> {
        try await RequestValidator(getInCoordinatesValidators()).validate(req, .query)
        let pageRequest = try req.pageRequest
        let getInRangeQuery = try req.query.decode(Waypoint.Request.ListInArea.self)
        
        var query: [String: Any] = [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "collapse": [
                "field": "id"
            ],
            "aggs": [
                "count": [
                    "cardinality": [
                        "field": "id"
                    ]
                ]
            ],
            "query": [
                "geo_bounding_box": [
                    "location": [
                        "top_left": [
                            "lat": getInRangeQuery.topLeftLatitude,
                            "lon": getInRangeQuery.topLeftLongitude
                        ],
                        "bottom_right": [
                            "lat": getInRangeQuery.bottomRightLatitude,
                            "lon": getInRangeQuery.bottomRightLongitude
                        ]
                    ]
                ]
            ]
        ]
        
        var sort: [[String: Any]] = []
        if let preferredLanguageCode = try? req.preferredLanguageCode() {
            sort.append(
                [
                    "_script": [
                        "type": "number",
                        "script": [
                            "lang": "painless",
                            "source": "doc['languageCode'].value == params.preferredLanguageCode ? 0 : doc['languagePriority'].value",
                            "params": [
                                "preferredLanguageCode": "\(preferredLanguageCode)"
                            ]
                        ],
                        "order": "asc"
                    ]
                ]
            )
        } else {
            sort.append(["languagePriority": "asc"])
        }
        sort.append(["title.keyword": "asc"])
        query["sort"] = sort
        
        return try await req.elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await req.elastic.custom("/\(ElasticModel.wildcardSchema)/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData)
            guard
                let responseJson = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                let aggregations = responseJson["aggregations"] as? [String: Any],
                let countAggregation = aggregations["count"] as? [String: Any],
                let count = countAggregation["value"] as? Int
            else {
                throw Abort(.internalServerError)
            }
            let items = response.hits.hits.map(\.source).map {
                Waypoint.Detail.List(id: $0.id, title: $0.title, slug: $0.slug, location: .init(latitude: $0.location.lat, longitude: $0.location.lon))
            }
            return Page(items: items, metadata: .init(page: pageRequest.page, per: pageRequest.per, total: count))
        }
    }
}
