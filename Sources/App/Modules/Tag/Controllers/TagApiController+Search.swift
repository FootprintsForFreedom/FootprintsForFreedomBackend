//
//  TagApiController+Search.swift
//  
//
//  Created by niklhut on 03.06.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

extension TagApiController {
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    // GET: api/tags/search?text=searchText
    func searchApi(_ req: Request) async throws -> Page<Tag.Detail.List> {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchQuery = try req.query.decode(RepositoryDefaultSearchQuery.self)
        
        guard searchQuery.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }
        
        let pageRequest = try req.query.decode(PageRequest.self)
        
        return try await search(searchQuery, pageRequest, on: req.elastic)
            .map { .init(id: $0.id, title: $0.title, slug: $0.slug) }
    }
    
    func search(_ searchQuery: RepositoryDefaultSearchQuery, _ pageRequest: PageRequest, on elastic: ElasticHandler) async throws -> Page<ElasticModel> {
        let query: [String: Any] = [
            "from": (pageRequest.page - 1) * pageRequest.per,
            "size": pageRequest.per,
            "query": [
                "multi_match": [
                    "query": searchQuery.text,
                    "fields": [ "title", "keywords"]
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
    
    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
    }
}
