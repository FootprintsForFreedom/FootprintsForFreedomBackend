//
//  MediaApiController+Search.swift
//  
//
//  Created by niklhut on 04.06.22.
//

import Vapor
import Fluent

extension MediaApiController {
    
    @AsyncValidatorBuilder
    func searchValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("text")
        KeyedContentValidator<String>.required("languageCode")
    }
    
    struct SearchQuery: Codable {
        let text: String
        let languageCode: String
    }
    
    func searchApi(_ req: Request) async throws -> Page<Media.Detail.List> {
        try await RequestValidator(searchValidators()).validate(req, .query)
        let searchQuery = try req.query.decode(SearchQuery.self)
        
        guard searchQuery.text.trimmingCharacters(in: .whitespacesAndNewlines) != "" else {
            throw Abort(.badRequest)
        }
        let searchText = searchQuery.text.lowercased()
        
        let allDetails = try await MediaDetailModel
            .query(on: req.db)
        // only search verified details
            .filter(\.$status ~~ [.verified, .deleteRequested])
            .join(parent: \.$language)
        // only search details with given language
            .filter(LanguageModel.self, \.$languageCode == searchQuery.languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
        // get all verified details for the repository in the specified language
            .all()
        
        let newestDetailsForRepositories = try allDetails
        // group the details by repository id
            .grouped(by: \.$repository.id)
        // get the newest detail for each repository
            .map { $1.sorted { $0.updatedAt! > $1.updatedAt! }.first! }
        // load the tag for all remaining details
        
        var detailInLanguageForTagRepository = [TagRepositoryModel.IDValue: TagDetailModel]()
        
        let filteredDetails = try await newestDetailsForRepositories
            .concurrentMap { mediaDetail -> (MediaDetailModel, [TagDetailModel]) in
                let tagRepositoryIds = try await MediaTagModel.query(on: req.db)
                    .filter(\.$media.$id == mediaDetail.$repository.id)
                    .field(\.$tag.$id)
                    .unique()
                    .all()
                    .map(\.$tag.id)
                
                let tagDetails = try await tagRepositoryIds
                    .concurrentCompactMap { repositoryId -> TagDetailModel? in
                        if let detail = detailInLanguageForTagRepository[repositoryId] {
                            return detail
                        } else {
                            guard let detail = try await TagDetailModel
                                .query(on: req.db)
                                .join(parent: \.$language)
                                .filter(LanguageModel.self, \.$languageCode == searchQuery.languageCode)
                                .filter(\.$repository.$id == repositoryId)
                                .filter(\.$status ~~ [.verified, .deleteRequested])
                                .sort(\.$updatedAt, .descending) // newest first
                                .first()
                            else {
                                return nil
                            }
                            detailInLanguageForTagRepository[repositoryId] = detail
                            return detail
                        }
                    }
                
                return (mediaDetail, tagDetails)
            }
            .filter { mediaDetail, tagDetails in
                return mediaDetail.title.lowercased().contains(searchText) ||
                mediaDetail.detailText.lowercased().contains(searchText) ||
                tagDetails.contains { $0.title.lowercased().contains(searchText) } ||
                tagDetails.contains { $0.keywords.contains { $0.lowercased().contains(searchText) } }
            }
            .map { $0.0 }
        
        let count = filteredDetails.count
        let page = try req.query.decode(PageRequest.self)
        
        let relevantDetails = filteredDetails.dropFirst((page.page - 1) * page.per).prefix(page.per)
        
        return try await Page(
            items: relevantDetails.concurrentMap { detail in
                try await detail.$media.load(on: req.db)
                return .init(
                    id: detail.$repository.id,
                    title: detail.title,
                    slug: detail.slug,
                    group: detail.media.group,
                    thumbnailFilePath: detail.media.relativeThumbnailFilePath
                )
            },
            metadata: PageMetadata(page: page.page, per: page.per, total: count)
        )
    }
    
    func setupSearchRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        baseRoutes.get("search", use: searchApi)
    }
}
