//
//  DetailChangesContent.swift
//  
//
//  Created by niklhut on 24.05.22.
//

import Foundation

public struct DetailChangesObject: Codable {
    public let from: UUID
    public let to: UUID
    
    public init(from: UUID, to: UUID) {
        self.from = from
        self.to = to
    }
}
