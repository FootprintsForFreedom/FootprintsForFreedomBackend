//
//  RepositoryPagedListController.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryPagedListController: RepositoryController {
    func list(_ req: Request) async throws -> Page<Repository>
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<Repository>) async throws -> QueryBuilder<Repository>
    func afterList(_ req: Request, _ repositories: Page<Repository>) async throws -> Page<Repository>
}

extension RepositoryPagedListController {
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<Repository>) async throws -> QueryBuilder<Repository> {
        queryBuilder
    }
    
    func afterList(_ req: Request, _ repositories: Page<Repository>) async throws -> Page<Repository> {
        repositories
    }
    
    func list(_ req: Request) async throws -> Page<Repository> {
        let queryBuilder = Repository.query(on: req.db)
        let list = try await beforeList(req, queryBuilder)
        // only return repositories with verified media details inside
            .join(children: \._$details)
            .filter(Detail.self, \._$status ~~ [.verified, .deleteRequested])
        // only return details which have an activated langauge
            .join(from: Detail.self, parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
        // only select the id field and return each id only once
            .field(\._$id)
            .unique()
            .paginate(for: req)
        return try await afterList(req, list)
    }
}
