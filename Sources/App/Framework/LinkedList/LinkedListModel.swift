//
//  LinkedListModel.swift
//  
//
//  Created by niklhut on 13.02.22.
//

import Fluent

protocol LinkedListModel: LinkedList, Model where NodeObject: NodeModel {
    func appendAndSave(_ value: Element, on db: Database) async throws -> NodeObject
    func remove(node: NodeObject, on db: Database) async throws -> Element
    func removeAll(on db: Database) async throws
}

extension LinkedListModel {
    func appendAndSave(_ value: Element, on db: Database) async throws -> NodeObject {
        let nodeObject = self.append(value)
        try await nodeObject.create(on: db)
        return nodeObject
    }
    
    func remove(node: NodeObject, on db: Database) async throws -> Element {
        /// unlink the node
        self.unlink(node: node)
        /// save the updated links on previous and next node
        try await node.previous?.update(on: db)
        try await node.next?.update(on: db)
        /// remove the node
        try await node.delete(on: db)
        return node.value
    }
    
    func removeAll(on db: Database) async throws {
        if let node = current {
            while let previous = node.previous {
                try await previous.delete(on: db)
            }
            while let next = node.next {
                try await next.delete(on: db)
            }
            try await node.delete(on: db)
        }
    }
}
