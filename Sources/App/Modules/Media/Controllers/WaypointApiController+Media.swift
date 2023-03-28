//
//  WaypointApiController+Media.swift
//  
//
//  Created by niklhut on 17.05.22.
//

import Vapor
import AppApi
import ElasticsearchNIOClient

extension WaypointApiController {
    func listMedia(_ req: Request) async throws -> AppApi.Page<Media.Detail.List> {
        let pageRequest = try req.pageRequest
        let waypointRepository = try await repository(req)
        
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
        
        let mediaQuery: [String: Any] = try [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "collapse": [
                "field": "id"
            ],
            "query": [
                "term": [
                    "waypointId": [
                        "value": waypointRepository.requireID().uuidString
                    ]
                ]
            ],
            "aggs": [
                "count": [
                    "cardinality": [
                        "field": "id"
                    ]
                ]
            ],
            "sort": sort
        ]
        
        return try await req.elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: mediaQuery)
            let responseData = try await req.elastic.custom("/\(MediaSummaryModel.Elasticsearch.wildcardSchema)/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<MediaSummaryModel.Elasticsearch>.self, from: responseData)
            guard
                let responseJson = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                let aggregations = responseJson["aggregations"] as? [String: Any],
                let countAggregation = aggregations["count"] as? [String: Any],
                let count = countAggregation["value"] as? Int
            else {
                throw Abort(.internalServerError)
            }
            return Page(
                items: response.hits.hits.map { MediaApiController().listOutput(req, $0.source) },
                metadata: PageMetadata(page: pageRequest.page, per: pageRequest.per, total: count)
            )
        }
    }
    
    func setupMediaRoute(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get("media", use: listMedia)
    }
}
