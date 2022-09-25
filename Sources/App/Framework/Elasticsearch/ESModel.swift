//
//  File.swift
//  
//
//  Created by niklhut on 21.09.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient


// TODO: name and move

protocol ElasticModelController: RepositoryController {
    /// The database model.
    associatedtype ElasticModel: ElasticModelInterface
}

extension ElasticModelController {
    func findBy(_ id: UUID, _ preferredLanguageCode: String?, on elastic: ElasticHandler) async throws -> (model: ElasticModel, availableLanguageCodes: [String]) {
        var query: [String : Any] = [
            "collapse": [
                "field": "id"
            ],
            "query": [
                "match": [
                    "id": id.uuidString
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
        
        guard
            let queryData = try? JSONSerialization.data(withJSONObject: query),
            let responseData = try? await elastic.custom("/\(ElasticModel.schema)/_search", method: .GET, body: queryData),
            let response = try? ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData),
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
    
    func findBy(_ slug: String, on elastic: ElasticHandler) async throws -> (model: ElasticModel, availableLanguageCodes: [String]) {
        let query: [String : Any] = [
            "query": [
                "match": [
                    "slug": "\(slug)"
                ]
            ]
        ]
        
        guard
            let queryData = try? JSONSerialization.data(withJSONObject: query),
            let responseData = try? await elastic.custom("/\(ElasticModel.schema)/_search", method: .GET, body: queryData),
            let response = try? ElasticHandler.newJSONDecoder().decode(ESGetMultipleDocumentsResponse<ElasticModel>.self, from: responseData),
            response.hits.hits.count <= 1
        else {
            throw Abort(.internalServerError)
        }
        guard let detail = response.hits.hits.first?.source else {
            throw Abort(.notFound)
        }
        
        let languageCodesQuery: [String: Any] = [
            "_source": false,
            "query": [
                "match": [ "id": "\(detail.id)" ]
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
        
        guard
            let languageCodesQueryData = try? JSONSerialization.data(withJSONObject: languageCodesQuery),
            let languageCodesResponseData = try? await elastic.custom("/\(ElasticModel.schema)/_search", method: .GET, body: languageCodesQueryData),
            let responseJson = try? JSONSerialization.jsonObject(with: languageCodesResponseData) as? [String: Any],
            let aggregations = responseJson["aggregations"] as? [String: Any],
            let languageCodesAggregation = aggregations["languageCodes"] as? [String: Any],
            let languageCodes = languageCodesAggregation["buckets"] as? [[String: Any]]
        else {
            throw Abort(.internalServerError)
        }
        
        return (detail, languageCodes.compactMap { $0["key"] as? String })
    }
}

protocol ApiElasticDetailController: ElasticModelController {
    /// The detail object content.
    associatedtype DetailObject: Content
    
    /// The detail output for a model.
    /// - Parameters:
    ///   - req: The request on which  to detail the model.
    ///   - model: The model to be detailed.
    /// - Returns: The model detail object.
    func detailOutput(_ req: Request, _ model: ElasticModel, _ availableLanguageCodes: [String]) async throws -> DetailObject
    
    /// The detail api action.
    /// - Parameter req: The request on which to detail the model.
    /// - Returns: The model detail object.
    func detailApi(_ req: Request) async throws -> DetailObject
    
    /// The detail by slug api action.
    ///
    /// Instead of finding the repository by its id this function searches the unique slugs of the details to find the requested repository detail.
    ///
    /// - Parameter req: The request on which to detail the repository.
    /// - Returns: The repository detail object.
    func detailBySlugApi(_ req: Request) async throws -> DetailObject
    
    /// Sets up the model detail routes.
    /// - Parameter routes: The routes on which to setup the model detail routes.
    func setupDetailRoutes(_ routes: RoutesBuilder)
}

extension ApiElasticDetailController {
    func detailApi(_ req: Request) async throws -> DetailObject {
        let (model, availableLanguageCodes) = try await findBy(identifier(req), req.preferredLanguageCode(), on: req.elastic)
        return try await detailOutput(req, model, availableLanguageCodes)
    }
    
    func detailBySlugApi(_ req: Request) async throws -> DetailObject {
        let (model, availableLanguageCodes) = try await findBy(slug(req), on: req.elastic)
        return try await detailOutput(req, model, availableLanguageCodes)
    }
    
    func setupDetailRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.get(use: detailApi)
        
        let slugRoutes = baseRoutes.grouped("find").grouped(ApiModel.pathIdComponent)
        slugRoutes.get(use: detailBySlugApi)
    }
}

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
        let responseData = try await req.elastic.custom("/\(ElasticModel.schema)/_search", method: .GET, body: queryData)
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

protocol ApiElasticPagedListController: ElasticPagedListController {
    /// The list object content.
    associatedtype ListObject: Content
    
    
    /// The detail output for a page of repositories.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repositories: The repositories to be in the output.
    /// - Returns: A paged list of list objects.
    func listOutput(_ req: Request, _ models: Page<ElasticModel>) async throws -> Page<ListObject>
    
    /// The detail output for one repository.
    /// - Parameters:
    ///   - req: The request on which the repositories were fetched.
    ///   - repository: The repository to be in the output.
    /// - Returns: A list object of the repository and detail.
    func listOutput(_ req: Request, _ model: ElasticModel) async throws -> ListObject
    
    /// The list repositories api action.
    /// - Parameter req: The request on which to list the repositories.
    /// - Returns: A paged list of the repositories.
    func listApi(_ req: Request) async throws -> Page<ListObject>
    
    /// Sets up the list repository routes.
    /// - Parameter routes: The routes on which to setup the list repository routes.
    func setupListRoutes(_ routes: RoutesBuilder)
}

extension ApiElasticPagedListController {
    func listApi(_ req: Request) async throws -> Page<ListObject> {
        let models = try await list(req)
        return try await listOutput(req, models)
    }
    
    func listOutput(_ req: Request, _ models: Page<ElasticModel>) async throws -> Page<ListObject> {
        try await models.concurrentCompactMap { model in
            try await listOutput(req, model)
        }
    }
    
    func setupListRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get(use: listApi)
    }
}
