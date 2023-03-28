//
//  PagedListController+Repository.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

extension PagedListController where Self: DatabaseRepositoryController {
    func list(_ req: Request) async throws -> Page<DatabaseModel> {
        let queryBuilder = DatabaseModel.query(on: req.db)
        let list = try await beforeList(req, queryBuilder)
        // only return repositories with verified media details inside
            .join(children: \._$details)
            .filter(Detail.self, \._$verifiedAt != nil)
        // only return details which have an activated language
            .join(from: Detail.self, parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
        // only select the id field and return each id only once
            .field(\._$id)
            .unique()
            .paginate(for: req)
        return try await afterList(req, list)
    }
}
