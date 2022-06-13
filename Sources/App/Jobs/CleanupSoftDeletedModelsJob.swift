//
//  CleanupSoftDeletedModelsJob.swift
//  
//
//  Created by niklhut on 13.06.22.
//

import Vapor
import Fluent
import Queues

struct CleanupSoftDeletedModelsJob: AsyncScheduledJob {
    func cleanupSoftDeleted<Model>(_ modelType: Model.Type, on db: Database) async throws where Model: Timestamped {
        guard let softDeletedLifetime = Environment.softDeletedLifetime else {
            return
        }
        let dayInSeconds = 60 * 60 * 24
        
        try await modelType
            .query(on: db)
            .withDeleted() // also query soft deleted models
            .filter(\._$deletedAt < Date().addingTimeInterval(TimeInterval(-1 * softDeletedLifetime * dayInSeconds))) // only select models that are older than the specified amount of days
            .delete(force: true) // and delete them
    }
    
    func run(context: QueueContext) async throws {
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
