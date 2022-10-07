//
//  ElasticPagedListController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

protocol ElasticPagedListController: ElasticModelController {
    func sortList(_ sort: inout [[String: Any]]) async throws
    
    func list(_ req: Request) async throws -> Page<ElasticModel>
}

extension ElasticPagedListController {
    func sortList(_ sort: inout [[String: Any]]) async throws { }
    
    func list(_ req: Request) async throws -> Page<ElasticModel> {
        let pageRequest = try req.query.decode(PageRequest.self)
        
        var query: [String : Any] = [
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
        sort.append([ "title.keyword": "asc" ])
        try await sortList(&sort)
        query["sort"] = sort
        
        let queryData = try JSONSerialization.data(withJSONObject: query)
        let responseData = try await req.elastic.custom("/\(ElasticModel.wildcardSchema)/_search", method: .GET, body: queryData)
        guard
            let response = try? ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData),
            let responseJson = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            let aggregations = responseJson["aggregations"] as? [String: Any],
            let countAggregation = aggregations["count"] as? [String: Any],
            let count = countAggregation["value"] as? Int
        else {
            throw Abort(.internalServerError)
        }
        
        return Page(
            items: response.hits.hits.map { $0.source },
            metadata: PageMetadata(page: pageRequest.page, per: pageRequest.per, total: count)
        )
    }
}