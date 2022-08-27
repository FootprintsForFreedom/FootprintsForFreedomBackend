//
//  CleanupOldVerifiedModelsJob.swift
//  
//
//  Created by niklhut on 12.08.22.
//

import Vapor
import Fluent
import Queues

/// A job which clean up old verified models after a certain time.
struct CleanupOldVerifiedModelsJob: AsyncScheduledJob {
    
    func cleanupOldVerified<Model>(_ modelType: Model.Type, on app: Application) async throws where Model: TitledDetailModel {
        /// Get the old verified lifetime or return.
        guard let oldVerifiedLifetime = Environment.oldVerifiedLifetime else {
            return
        }
        let dayInSeconds = 60 * 60 * 24
        
        let potentialOldVerifiedModels = try await modelType
            .query(on: app.db)
            .filter(\._$status == .verified)
            .filter(\._$updatedAt < Date().addingTimeInterval(TimeInterval(-1 * oldVerifiedLifetime * dayInSeconds))) // only select models that were updated before the specified amount of days
            .with(\._$language)
            .all()
        
        try await potentialOldVerifiedModels.asyncForEach { model in
            if let currentVerifiedModel = try await model.firstFor(model.repository, model.language.languageCode, needsToBeVerified: true, on: app.db), currentVerifiedModel.id != model.id {
                if let model = model as? MediaDetailModel {
                    try await model.$media.load(on: app.db)
                    let fileDetailsCount = try await model.media.$details.query(on: app.db).count()
                    if fileDetailsCount == 1 { // only this detail
                        // since the file model is not force deleted the file cleanup will be handled by the cleanup soft deleted models job.
                        try await model.media.delete(on: app.db)
                    }
                }
                
                // delete the model but still leave it recoverable since it is not force deleted.
                try await model.delete(on: app.db)
            }
        }
    }
    
    func cleanupOldVerified<Model>(_ modelType: Model.Type, on app: Application) async throws where Model: DetailModel {
        /// Get the old verified lifetime or return.
        guard let oldVerifiedLifetime = Environment.oldVerifiedLifetime else {
            return
        }
        let dayInSeconds = 60 * 60 * 24
        
        let potentialOldVerifiedModels = try await modelType
            .query(on: app.db)
            .filter(\._$status == .verified)
            .filter(\._$updatedAt < Date().addingTimeInterval(TimeInterval(-1 * oldVerifiedLifetime * dayInSeconds))) // only select models that were updated before the specified amount of days
            .all()
        
        try await potentialOldVerifiedModels.asyncForEach { model in
            if let currentVerifiedModel = try await model.firstFor(model.repository, needsToBeVerified: true, on: app.db), currentVerifiedModel.id != model.id {
                // delete the model but still leave it recoverable since it is not force deleted.
                try await model.delete(on: app.db)
            }
        }
        
        // TODO: orphaned media files?
    }
    
    func run(context: QueueContext) async throws {
        /// All detail model types to cleanup.
        let detailObjectTypes: [any DetailModel.Type] = [
            TagDetailModel.self,
            MediaDetailModel.self,
            WaypointDetailModel.self,
            WaypointLocationModel.self,
            StaticContentDetailModel.self,
        ]
        
        try await detailObjectTypes.asyncForEach { detailObjectType in
            try await cleanupOldVerified(detailObjectType, on: context.application)
        }
    }
}
