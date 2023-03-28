//
//  Status.swift
//  
//
//  Created by niklhut on 05.06.22.
//

import Foundation

/// Used to indicate the status of a model.
public enum Status: String, Codable, CaseIterable, ApiModuleInterface {
    /// The model was created and has not been reviewed yet. The model is not visible to users.
    case pending
    /// The model was reviewed and verified. The model is visible to users.
    case verified
    /// The model was visible and it was requested to delete it. The model is visible to users.
    case deleteRequested
}
