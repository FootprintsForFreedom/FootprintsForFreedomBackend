//
//  ElasticPagedListController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

/// Streamlines paged loading of all ``ElasticModelController/ElasticModel``s of one Type from the database.
protocol ElasticPagedListController: ElasticModelController {
    /// A json convertible array which extends the default search capabilities
    /// - Parameter sort: The default sort object which can be changed.
    func sortList(_ sort: inout [[String: Any]]) async throws
    
    /// Queries elasticsearch to get a paged list of elastic models.
    /// - Parameter req: The request on which to perform the list.
    /// - Returns: A page of elastic models.
    func list(_ req: Request) async throws -> Page<ElasticModel>
}

extension ElasticPagedListController {
    func sortList(_ sort: inout [[String: Any]]) async throws { }
    
    func list(_ req: Request) async throws -> Page<ElasticModel> {
        let pageRequest = try req.pageRequest
        
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
        sort.append([ "title.keyword": "asc"])
        try await sortList(&sort)
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
            return Page(
                items: response.hits.hits.map(\.source),
                metadata: PageMetadata(page: pageRequest.page, per: pageRequest.per, total: count)
            )
        }
    }
}
