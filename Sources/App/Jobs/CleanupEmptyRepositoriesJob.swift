//
//  CleanupEmptyRepositoriesJob.swift
//  
//
//  Created by niklhut on 12.06.22.
//

import Vapor
import Fluent
import Queues

/// A job which cleans up repositories without any detail models.
struct CleanupEmptyRepositoriesJob: AsyncScheduledJob {
    /// Cleans up all repositories without details for the given repository type,
    /// - Parameters:
    ///   - repositoryType: The type of the repository model.
    ///   - db: The database on which to search for and delete the repositories without details.
    private func cleanupEmpty<Repository>(_ repositoryType: Repository.Type, on db: Database) async throws where Repository: RepositoryModel {
        // SELECT * FROM ParentTable WHERE ParentID NOT IN (SELECT DISTINCT ParentID FROM ChildTable)
        
        /// All ids of the repository models referenced in the detail models.
        let parentIds = try await repositoryType.Detail
            .query(on: db)
            .withDeleted()
            .field(\._$repository.$id)
            .unique()
            .all()
            .map(\._$repository.id)
        
        /// Delete all repositories not in the ids referenced by the detail models.
        try await repositoryType
            .query(on: db)
            .withDeleted()
            .filter(\._$id !~ parentIds) // select all repositories that are not in the parent ids array
            .delete() // and delete them
        
        // Don't force delete the repositories since this function does not handle deleting media files.
        // Instead only soft delete them, which also leaves the repositories recoverable.
        // Then the cleanup soft deleted job will delete the repositories and handle deleting media files.
    }
    
    func run(context: QueueContext) async throws {
        /// All repository types to cleanup.
        let repositoryTypes: [any RepositoryModel.Type] = [
            WaypointRepositoryModel.self,
            MediaRepositoryModel.self,
            MediaFileModel.self,
            TagRepositoryModel.self
        ]
        
        try await repositoryTypes.asyncForEach { repositoryType in
            try await cleanupEmpty(repositoryType, on: context.application.db)
        }
    }
}
