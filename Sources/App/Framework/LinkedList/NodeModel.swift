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
    
    var currentObjectInListProperty: OptionalParentProperty<Self, EditableTextRepositoryModel> { get }
    var lastObjectInListProperty: OptionalParentProperty<Self, EditableTextRepositoryModel> { get }
    
    func loadPreviousAndNext(on db: Database) async throws
    func loadList(on db: Database) async throws
    func loadAll(on db: Database) async throws
}

extension NodeModel {
    func loadPreviousAndNext(on db: Database) async throws {
        try await nextProperty.load(on: db)
        try await previousProperty.load(on: db)
    }
    
    func loadList(on db: Database) async throws {
        try await currentObjectInListProperty.load(on: db)
        try await lastObjectInListProperty.load(on: db)
    }
    
    func loadAll(on db: Database) async throws {
        try await loadPreviousAndNext(on: db)
        try await loadList(on: db)
    }
}
