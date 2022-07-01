//
//  CleanupSoftDeletedModelsJob.swift
//  
//
//  Created by niklhut on 13.06.22.
//

import Vapor
import Fluent
import Queues

/// A job which cleans up soft deleted models after a certain time..
struct CleanupSoftDeletedModelsJob: AsyncScheduledJob {
    /// Cleans up all soft deleted models older than specified in the environment.
    ///
    /// If no lifetime for soft deleted models is set no soft deleted models will be deleted.
    ///
    /// - Parameters:
    ///   - modelType: The type of the model whose soft deleted models are to be deleted.
    ///   - db: The database on which to find and delete the soft deleted models.
    func cleanupSoftDeleted<Model>(_ modelType: Model.Type, on db: Database) async throws where Model: Timestamped {
        /// Get the soft deleted lifetime or return.
        guard let softDeletedLifetime = Environment.softDeletedLifetime else {
            return
        }
        let dayInSeconds = 60 * 60 * 24
        
        /// Query the model type and delete all models which were soft deleted and whose lifetime expired.
        try await modelType
            .query(on: db)
            .withDeleted() // also query soft deleted models
            .filter(\._$deletedAt < Date().addingTimeInterval(TimeInterval(-1 * softDeletedLifetime * dayInSeconds))) // only select models that are older than the specified amount of days
            .delete(force: true) // and delete them
    }
    
    func run(context: QueueContext) async throws {
        /// All model types to cleanup.
        let timestampedTypes: [any Timestamped.Type] = [
            TagRepositoryModel.self,
            TagDetailModel.self,
            TagReportModel.self,
            MediaRepositoryModel.self,
            MediaDetailModel.self,
            MediaFileModel.self,
            MediaReportModel.self,
            WaypointRepositoryModel.self,
            WaypointDetailModel.self,
            WaypointLocationModel.self,
            WaypointReportModel.self,
            StaticContentRepositoryModel.self,
            StaticContentDetailModel.self
        ]
        
        try await timestampedTypes.concurrentForEach(withPriority: .background) { timestampedType in
            try await cleanupSoftDeleted(timestampedType, on: context.application.db)
        }
    }
}