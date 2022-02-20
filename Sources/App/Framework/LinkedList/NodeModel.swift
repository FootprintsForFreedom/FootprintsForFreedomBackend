//
//  NodeModel.swift
//  
//
//  Created by niklhut on 13.02.22.
//

import Fluent

protocol NodeModel: Equatable, DatabaseModelInterface {
    var next: Self? { get set }
    var previous: Self? { get set }
    
    var nextProperty: OptionalChildProperty<Self, Self> { get }
    var previousProperty: OptionalParentProperty<Self, Self> { get }
    
    func load(on db: Database) async throws
    
    func deleteAll(on db: Database) async throws
}

extension NodeModel {
    func load(on db: Database) async throws {
        try await nextProperty.load(on: db)
        try await previousProperty.load(on: db)
    }
    
    func deleteAll(on db: Database) async throws {
        try await self.load(on: db)
        var nodeToDelete = self.next
        while nodeToDelete != nil {
            try await nodeToDelete!.nextProperty.load(on: db)
            let nextNode = nodeToDelete!.next
            try await nodeToDelete!.delete(on: db)
            nodeToDelete = nextNode
        }
        nodeToDelete = self.previous
        while nodeToDelete != nil {
            try await nodeToDelete!.previousProperty.load(on: db)
            let previousNode = nodeToDelete!.previous
            try await nodeToDelete!.delete(on: db)
            nodeToDelete = previousNode
        }
        try await self.delete(on: db)
    }
}
