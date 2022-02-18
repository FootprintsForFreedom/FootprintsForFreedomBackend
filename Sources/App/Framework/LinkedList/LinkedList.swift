//
//  LinkedList.swift
//
//
//  Created by niklhut on 13.02.22.
//

import Foundation

protocol LinkedList: AnyObject where NodeObject.NodeObject == NodeObject {
    associatedtype NodeObject: Node
    typealias Element = NodeObject.Element

    var current: NodeObject! { get set }
    var last: NodeObject! { get set }

    var isEmpty: Bool { get}
    
    func append(_ value: Element) -> NodeObject
    @discardableResult
    func unlink(_ node: NodeObject) -> Element
    func unlinkAll()
    
    func incrementCurrent() throws
    func swap(_ node1: inout NodeObject, _ node2: inout NodeObject)
}

extension LinkedList {
    var isEmpty: Bool {
        current == nil
    }
    
    func append(_ value: Element) -> NodeObject {
        let newNode = NodeObject(value: value)
        if let lastNode = last {
            newNode.previous = lastNode
            lastNode.next = newNode
        } else {
            current = newNode
        }
        last = newNode
        return newNode
    }
    
    @discardableResult
    func unlink(_ node: NodeObject) -> Element {
        if let previousNode = node.previous {
            if let nextNode = node.next {
                previousNode.next = nextNode
                nextNode.previous = previousNode
            } else {
                previousNode.next = nil
            }
        } else if let nextNode = node.next {
            nextNode.previous = nil
        }
        
        if node == current {
            current = node.previous ?? node.next
        }
        if node == last {
            last = node.previous
        }
        
        return node.value
    }
    
    func unlinkAll() {
        current = nil
        last = nil
    }
    
    func incrementCurrent() throws {
        guard let nextNode = current?.next else {
            throw LinkedListError.noNextValue
        }
        current = nextNode
    }
    
    func swap(_ node1: inout NodeObject, _ node2: inout NodeObject) {
        if node1 == node2 {
            return
        }
        
        /// swap properties of list
        if node1 == current {
            current = node2
        } else if node2 == current {
            current = node1
        }
        if node1 == last {
            last = node2
        } else if node2 == last {
            last = node1
        }
        
        /// swap references to the nodes
        node1.previous?.next = node2
        node1.next?.previous = node2
        node2.previous?.next = node1
        node2.next?.previous = node1
        
        /// swap the refrences in the nodes
        let nodeBeforeNode1 = node1.previous
        node1.previous = node2.previous
        node2.previous = nodeBeforeNode1
        
        let nodeAfterNode1 = node1.next
        node1.next = node2.next
        node2.next = nodeAfterNode1
    }
}
