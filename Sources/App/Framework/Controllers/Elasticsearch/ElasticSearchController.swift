//
//  ElasticSearchController.swift
//  
//
//  Created by niklhut on 10.10.22.
//

import Vapor
import Fluent
import ElasticsearchNIOClient

protocol ElasticSearchController: ElasticModelController {
    /// The elasticsearch search query to be used.
    /// - Returns: A json formatted array.
    /// - Parameters:
    ///   - searchContext: The search terms submitted by the user.
    ///   - elastic: An elastic handler to perform optional previous queries.
    func searchQuery(_ searchContext: RepositoryDefaultSearchContext, _ pageRequest: PageRequest, on elastic: ElasticHandler) async throws -> [String: Any]
    
    /// Searches elasticsearch to get a page of elastic models.
    /// - Parameters:
    ///   - searchQuery: The search query to use for search.
    ///   - pageRequest: The page request to paginate the results.
    ///   - elastic: The elastic handler to perform the search.
    /// - Returns: A page of elastic models.
    func search(_ searchContext: RepositoryDefaultSearchContext, _ pageRequest: PageRequest, on elastic: ElasticHandler) async throws -> Page<ElasticModel>
}

extension ElasticSearchController {
    func search(_ searchContext: RepositoryDefaultSearchContext, _ pageRequest: PageRequest, on elastic: ElasticHandler) async throws -> Page<ElasticModel> {
        let query = try await searchQuery(searchContext, pageRequest, on: elastic)
        
        do {
            let queryData = try JSONSerialization.data(withJSONObject: query)
            let responseData = try await elastic.custom("/\(ElasticModel.schema(for: searchContext.languageCode))/_search", method: .GET, body: queryData)
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
}