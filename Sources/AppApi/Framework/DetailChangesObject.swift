//
//  DetailChangesObject.swift
//  
//
//  Created by niklhut on 24.05.22.
//

import Foundation

/// Indicates between which models to detail changes.
public struct DetailChangesObject: Codable {
    /// The media detail which serves as the source of the changes.
    public let from: UUID
    /// The media detail which serves as the destination of the changes.
    public let to: UUID
    
    public init(from: UUID, to: UUID) {
        self.from = from
        self.to = to
    }
}
