//
//  DeleteController+Repository.swift
//
//
//  Created by niklhut on 26.05.22.
//

import Vapor

extension DeleteController where DatabaseModel: RepositoryModel, DatabaseModel.Detail.Repository == DatabaseModel {
    func delete(_ req: Request, _ repository: DatabaseModel) async throws {
        try await beforeDelete(req, repository)
        try await repository.delete(on: req.db)
        try await repository.deleteDependencies(on: req.db)
        try await afterDelete(req, repository)
    }
}
