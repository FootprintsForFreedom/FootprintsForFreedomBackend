//
//  TagApiController+Search.swift
//  
//
//  Created by niklhut on 03.06.22.
//

import Vapor
import Fluent

extension TagApiController {
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    struct SearchQuery: Codable {
        let text: String
        let languageCode: String
    }
    
    // GET: api/tags/search?text=searchText
    func searchApi(_ req: Request) async throws -> Page<Tag.Detail.List> {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchQuery = try req.query.decode(SearchQuery.self)
        
        guard searchQuery.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }
        let searchText = searchQuery.text.lowercased()
        
        let filteredDetails = try await TagDetailModel
            .query(on: req.db)
        // only search verified details
            .filter(\.$verifiedAt != nil)
            .join(parent: \.$language)
        // only search details with given language
            .filter(LanguageModel.self, \.$languageCode == searchQuery.languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        // get all verified details for the repository in the specified language
            .all()
        // group the details by repository id
            .grouped(by: \.$repository.id)
        // get the newest detail for each repository
            .map { $1.sorted { $0.verifiedAt! > $1.verifiedAt! }.first! }
        // filter the details according to the search text
            .filter {
                $0.title.lowercased().contains(searchText) ||
                $0.keywords.contains { $0.lowercased().contains(searchText) }
            }
        
        let count = filteredDetails.count
        let page = try req.query.decode(PageRequest.self)
        
        let relevantDetails = filteredDetails.dropFirst((page.page - 1) * page.per).prefix(page.per)
        
        return Page(
            items: relevantDetails.map { detail in
                return .init(id: detail.$repository.id, title: detail.title, slug: detail.slug)
            },
            metadata: PageMetadata(page: page.page, per: page.per, total: count)
        )
    }
    
    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
    }
}
