//
//  ElasticModelController.swift
//  
//
//  Created by niklhut on 07.10.22.
//

import Vapor
import ElasticsearchNIOClient

/// Streamlines controlling elasticsearch models.
protocol ElasticModelController: RepositoryController {
    /// The database model.
    associatedtype ElasticModel: ElasticModelInterface
    
    /// Finds a model by its id and preferred language code on elasticsearch.
    /// - Parameters:
    ///   - id: The model id.
    ///   - preferredLanguageCode: The preferred language code for the model.
    ///   - elastic: The elasticsearch handler on which to find the model.
    /// - Returns: The model with the given id and all available language codes for this model.
    func findBy(_ id: UUID, _ preferredLanguageCode: String?, on elastic: ElasticHandler) async throws -> (model: ElasticModel, availableLanguageCodes: [String])
    
    /// Finds a model by its slug on elasticsearch.
    /// - Parameters:
    ///   - slug: The detail's slug.
    ///   - elastic: The elasticsearch handler on which to find the model.
    /// - Returns: The model with the given slug and all available language codes for this model.
    func findBy(_ slug: String, on elastic: ElasticHandler) async throws -> (model: ElasticModel, availableLanguageCodes: [String])
}

extension ElasticModelController {
    func findBy(_ id: UUID, _ preferredLanguageCode: String?, on elastic: ElasticHandler) async throws -> (model: ElasticModel, availableLanguageCodes: [String]) {
        var query: [String : Any] = [
            "collapse": [
                "field": "id"
            ],
            "query": [
                "term": [
                    "id": [
                        "value": id.uuidString
                    ]
                ]
            ],
            "aggs": [
                "languageCodes": [
                    "terms": [
                        "field": "languageCode",
                        "size": 20
                    ]
                ]
            ]
        ]
        var sort: [[String: Any]] = []
        if let preferredLanguageCode = preferredLanguageCode {
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
        query["sort"] = sort
        
        return try await elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(ElasticModel.wildcardSchema)/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData)
            guard
                response.hits.hits.count <= 1,
                let responseJson = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                let aggregations = responseJson["aggregations"] as? [String: Any],
                let languageCodesAggregation = aggregations["languageCodes"] as? [String: Any],
                let languageCodes = languageCodesAggregation["buckets"] as? [[String: Any]]
            else {
                throw Abort(.internalServerError)
            }
            guard let detail = response.hits.hits.first?.source else {
                throw Abort(.notFound)
            }
            
            return (detail, languageCodes.compactMap { $0["key"] as? String })
        }
    }
    
    func findBy(_ slug: String, on elastic: ElasticHandler) async throws -> (model: ElasticModel, availableLanguageCodes: [String]) {
        let query: [String : Any] = [
            "query": [
                "term": [
                    "slug": [
                        "value": slug
                    ]
                ]
            ]
        ]
        
        return try await elastic.perform {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(ElasticModel.wildcardSchema)/_search", method: .GET, body: queryData)
            let response = try ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData)
            guard response.hits.hits.count <= 1 else {
                throw Abort(.internalServerError)
            }
            guard let detail = response.hits.hits.first?.source else {
                throw Abort(.notFound)
            }
            
            let languageCodesQuery: [String: Any] = [
                "_source": false,
                "query": [
                    "term": [
                        "id": [
                            "value": detail.id.uuidString
                        ]
                    ]
                ],
                "aggs": [
                    "languageCodes": [
                        "terms": [
                            "field": "languageCode",
                            "size": 20
                        ]
                    ]
                ]
            ]
            
            let languageCodesQueryData = try JSONSerialization.data(withJSONObject: languageCodesQuery)
            let languageCodesResponseData = try await elastic.custom("/\(ElasticModel.wildcardSchema)/_search", method: .GET, body: languageCodesQueryData)
            guard
                let responseJson = try JSONSerialization.jsonObject(with: languageCodesResponseData) as? [String: Any],
                let aggregations = responseJson["aggregations"] as? [String: Any],
                let languageCodesAggregation = aggregations["languageCodes"] as? [String: Any],
                let languageCodes = languageCodesAggregation["buckets"] as? [[String: Any]]
            else {
                throw Abort(.internalServerError)
            }
            
            return (detail, languageCodes.compactMap { $0["key"] as? String })
        }
    }
}
