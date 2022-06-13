//
//  CleanupEmptyRepositoriesJob.swift
//  
//
//  Created by niklhut on 12.06.22.
//

import Vapor
import Fluent
import Queues

struct CleanupEmptyRepositoriesJob: AsyncScheduledJob {
    private func cleanupEmpty<Repository>(_ repositoryType: Repository.Type, on db: Database) async throws where Repository: RepositoryModel {
        // SELECT * FROM ParentTable WHERE ParentID NOT IN (SELECT DISTINCT ParentID FROM ChildTable)
        let parentIds = try await repositoryType.Detail
            .query(on: db)
            .withDeleted()
            .field(\._$repository.$id)
            .unique()
            .all()
            .map(\._$repository.id)
        
        try await repositoryType
            .query(on: db)
            .withDeleted()
            .filter(\._$id !~ parentIds) // select all repositories that are not in the parent ids array
            .delete(force: true) // and delete them
    }
    
    func run(context: QueueContext) async throws {
        let repositoryTypes: [any RepositoryModel.Type] = [WaypointRepositoryModel.self, MediaRepositoryModel.self, TagRepositoryModel.self]
        
        try await repositoryTypes.concurrentForEach(withPriority: .background) { repositoryType in
            try await cleanupEmpty(repositoryType, on: context.application.db)
        }
    }
}
