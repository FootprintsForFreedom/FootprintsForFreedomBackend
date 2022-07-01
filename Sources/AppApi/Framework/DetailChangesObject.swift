//
//  DetailChangesObject.swift
//  
//
//  Created by niklhut on 24.05.22.
//

import Foundation

/// Object used to find out between which models to detail changes.
public struct DetailChangesObject: Codable {
    public let from: UUID
    public let to: UUID
    
    public init(from: UUID, to: UUID) {
        self.from = from
        self.to = to
    }
}
