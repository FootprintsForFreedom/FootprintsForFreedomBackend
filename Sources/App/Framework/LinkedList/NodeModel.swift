//
//  NodeModel.swift
//  
//
//  Created by niklhut on 13.02.22.
//

import Fluent

protocol NodeModel: Node, DatabaseModelInterface where NodeObject: DatabaseModelInterface {
    var nextProperty: OptionalChildProperty<Self, Self> { get }
    var previousProperty: OptionalParentProperty<Self, Self> { get }
    
    func load(on db: Database) async throws
}

extension NodeModel {
    func load(on db: Database) async throws {
        try await nextProperty.load(on: db)
        try await previousProperty.load(on: db)
    }
}
