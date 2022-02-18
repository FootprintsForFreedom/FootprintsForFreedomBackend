//
//  LinkedListTests.swift
//  
//
//  Created by niklhut on 13.02.22.
//

@testable import App
import XCTest

final class LinkedListTests: XCTestCase {
    /// Node with minimum protocol requirements
    final class MyNode: Node, Equatable {
        static func == (lhs: LinkedListTests.MyNode, rhs: LinkedListTests.MyNode) -> Bool {
            lhs.value == rhs.value
        }
        
        var value: Int
        var next: MyNode?
        var previous: MyNode?
        
        init(value: Int) {
            self.value = value
        }
    }
    
    /// Linked list with minimum protocol requirements
    final class MyLinkedList: LinkedList {
        typealias NodeObject = MyNode
        
        var current: NodeObject!
        var last: NodeObject!
    }
    
    func testLinkedListStartsEmpty() {
        let linkedList = MyLinkedList()
        
        XCTAssertTrue(linkedList.isEmpty)
        XCTAssertNil(linkedList.current)
        XCTAssertNil(linkedList.last)
    }
    
    func testAppend() {
        let linkedList = MyLinkedList()
        
        let firstValue = 1
        let firstNode = linkedList.append(firstValue)
        XCTAssertFalse(linkedList.isEmpty)
        XCTAssertEqual(firstNode.value, firstValue)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, firstNode)
        XCTAssertEqual(linkedList.last, firstNode)
        
        // Check the node is set up correctly
        XCTAssertNil(firstNode.previous)
        XCTAssertNil(firstNode.next)
        
        let secondValue = 2
        let secondNode = linkedList.append(secondValue)
        XCTAssertEqual(secondNode.value, secondValue)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, firstNode)
        XCTAssertEqual(linkedList.last, secondNode)
        
        // Check the nodes are set up correctly
        XCTAssertNil(firstNode.previous)
        XCTAssertEqual(firstNode.next, secondNode)
        XCTAssertEqual(secondNode.previous, firstNode)
        XCTAssertNil(secondNode.next)
        
        let thirdValue = 3
        let thirdNode = linkedList.append(thirdValue)
        XCTAssertEqual(thirdNode.value, thirdValue)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, firstNode)
        XCTAssertEqual(linkedList.last, thirdNode)
        
        // Check the nodes are set up correctly
        XCTAssertNil(firstNode.previous)
        XCTAssertEqual(firstNode.next, secondNode)
        XCTAssertEqual(secondNode.previous, firstNode)
        XCTAssertEqual(secondNode.next, thirdNode)
        XCTAssertEqual(thirdNode.previous, secondNode)
        XCTAssertNil(thirdNode.next)
    }
    
    func testMultipleAppends() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        XCTAssertEqual(values.count, 100)
        let nodes = values.map { linkedList.append($0) }
        
        // Check the list is set up correctly
        XCTAssertFalse(linkedList.isEmpty)
        XCTAssertEqual(linkedList.current, nodes.first)
        XCTAssertEqual(linkedList.last, nodes.last)
        
        for (index, node) in nodes.enumerated() {
            if node == nodes.first {
                XCTAssertNil(node.previous)
            } else {
                XCTAssertEqual(node.previous, nodes[index - 1])
            }
            if node == nodes.last {
                XCTAssertNil(node.next)
            } else {
                XCTAssertEqual(node.next, nodes[index + 1])
            }
        }
    }
    
    func testUnlinkLast() {
        let linkedList = MyLinkedList()
        
        let values = (1...10).map { $0 }
        var nodes = values.map { linkedList.append($0) }
        
        let removedValue = linkedList.unlink(nodes.last!)
        let confirmRemovedValue = nodes.removeLast()
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(nodes.count, values.count - 1)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, nodes.first)
        XCTAssertEqual(linkedList.last, nodes.last)
        
        for (index, node) in nodes.enumerated() {
            if node == nodes.first {
                XCTAssertNil(node.previous)
            } else {
                XCTAssertEqual(node.previous, nodes[index - 1])
            }
            if node == nodes.last {
                XCTAssertNil(node.next)
            } else {
                XCTAssertEqual(node.next, nodes[index + 1])
            }
        }
    }
    
    func testUnlinkCurrent() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        var nodes = values.map { linkedList.append($0) }
        
        let removedValue = linkedList.unlink(nodes.first!)
        let confirmRemovedValue = nodes.removeFirst()
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(nodes.count, values.count - 1)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, nodes.first)
        XCTAssertEqual(linkedList.last, nodes.last)
        
        for (index, node) in nodes.enumerated() {
            if node == nodes.first {
                XCTAssertNil(node.previous)
            } else {
                XCTAssertEqual(node.previous, nodes[index - 1])
            }
            if node == nodes.last {
                XCTAssertNil(node.next)
            } else {
                XCTAssertEqual(node.next, nodes[index + 1])
            }
        }
    }
    
    func testUnlinkCurrentAndLastNode() {
        let linkedList = MyLinkedList()
        
        let firstAndLastValue = 1
        let firstAndLastNode = linkedList.append(firstAndLastValue)
        XCTAssertEqual(firstAndLastNode.value, firstAndLastValue)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, firstAndLastNode)
        XCTAssertEqual(linkedList.last, firstAndLastNode)
        
        linkedList.unlink(firstAndLastNode)
        XCTAssertTrue(linkedList.isEmpty)
        XCTAssertNil(linkedList.current)
        XCTAssertNil(linkedList.last)
    }
    
    func testUnlinkMiddleNode() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        var nodes = values.map { linkedList.append($0) }
        
        let indexOfElementToRemove = Int.random(in: 1...nodes.count - 2)
        
        let removedValue = linkedList.unlink(nodes[indexOfElementToRemove])
        let confirmRemovedValue = nodes.remove(at: indexOfElementToRemove)
        XCTAssertEqual(removedValue, confirmRemovedValue.value)
        XCTAssertEqual(nodes.count, values.count - 1)
        
        // Check the list is set up correctly
        XCTAssertEqual(linkedList.current, nodes.first)
        XCTAssertEqual(linkedList.last, nodes.last)
        
        for (index, node) in nodes.enumerated() {
            if node == nodes.first {
                XCTAssertNil(node.previous)
            } else {
                XCTAssertEqual(node.previous, nodes[index - 1])
            }
            if node == nodes.last {
                XCTAssertNil(node.next)
            } else {
                XCTAssertEqual(node.next, nodes[index + 1])
            }
        }
    }
    
    func testUnlinkAll() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        var _ = values.map { linkedList.append($0) }
        
        linkedList.unlinkAll()
        XCTAssertTrue(linkedList.isEmpty)
        XCTAssertNil(linkedList.current)
        XCTAssertNil(linkedList.last)
    }
    
    func testIncrementCurrent() throws {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        let nodes = values.map { linkedList.append($0) }
        
        XCTAssertNotNil(linkedList.current)
        XCTAssertEqual(linkedList.current, nodes.first)
        
        try linkedList.incrementCurrent()
        XCTAssertEqual(linkedList.current, nodes[1])
    }
    
    func testIncrementCurrentFailsWhenCurrentIsLast() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        let nodes = values.map { linkedList.append($0) }
        linkedList.current = nodes.last
        
        XCTAssertNotNil(linkedList.current)
        XCTAssertEqual(linkedList.current, nodes.last)
        
        XCTAssertThrowsError(try linkedList.incrementCurrent()) { error in
            XCTAssertEqual(error as! LinkedListError, LinkedListError.noNextValue)
        }
    }
    
    func testIncrementCurrentFailsWhenListIsEmpty() {
        let linkedList = MyLinkedList()
        XCTAssertNil(linkedList.current)
        
        XCTAssertThrowsError(try linkedList.incrementCurrent()) { error in
            XCTAssertEqual(error as! LinkedListError, LinkedListError.noNextValue)
        }
    }
    
    func testSwap() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        var nodes = values.map { linkedList.append($0) }
        
        let firstIndexToSwap = nodes.firstIndex(of: nodes.randomElement()!)!
        var firstNodeToSwap = nodes[firstIndexToSwap]
        let secondIndexToSwap = nodes.firstIndex(of: nodes.randomElement()!)!
        var secondNodeToSwap = nodes[secondIndexToSwap]
        
        linkedList.swap(&firstNodeToSwap, &secondNodeToSwap)
        nodes[firstIndexToSwap] = firstNodeToSwap
        nodes[secondIndexToSwap] = secondNodeToSwap
        nodes.swapAt(firstIndexToSwap, secondIndexToSwap)
        
        // check swap was correct by iterating through linked list
        var currentNode = linkedList.last!
        var count = 0
        while let previousNode = currentNode.previous {
            XCTAssertEqual(previousNode.next, currentNode)
            if let nextNode = currentNode.next {
                XCTAssertEqual(nextNode.previous, currentNode)
            }
            count += 1
            currentNode = previousNode
        }
        XCTAssertEqual(count, nodes.count - 1)
        
        // test the same by checking every element of array
        for (index, node) in nodes.enumerated() {
            if node == nodes.first {
                XCTAssertNil(node.previous)
                XCTAssertEqual(node, linkedList.current)
            } else {
                XCTAssertEqual(node.previous, nodes[index - 1])
            }
            if node == nodes.last {
                XCTAssertNil(node.next)
                XCTAssertEqual(node, linkedList.last)
            } else {
                XCTAssertEqual(node.next, nodes[index + 1])
            }
        }
    }
    
    func testSwapFirstAndLast() {
        let linkedList = MyLinkedList()
        
        let values = (1...100).map { $0 }
        var nodes = values.map { linkedList.append($0) }
        
        let firstIndexToSwap = 0
        var firstNodeToSwap = nodes[firstIndexToSwap]
        let secondIndexToSwap = nodes.count - 1
        var secondNodeToSwap = nodes[secondIndexToSwap]
        
        linkedList.swap(&firstNodeToSwap, &secondNodeToSwap)
        nodes[firstIndexToSwap] = firstNodeToSwap
        nodes[secondIndexToSwap] = secondNodeToSwap
        nodes.swapAt(firstIndexToSwap, secondIndexToSwap)
        
        XCTAssertEqual(linkedList.current, nodes.first)
        XCTAssertEqual(linkedList.last, nodes.last)
        
        // check swap was correct by iterating through linked list
        for (index, node) in nodes.enumerated() {
            if node == nodes.first {
                XCTAssertNil(node.previous)
                XCTAssertEqual(node, linkedList.current)
            } else {
                XCTAssertEqual(node.previous, nodes[index - 1])
            }
            if node == nodes.last {
                XCTAssertNil(node.next)
                XCTAssertEqual(node, linkedList.last)
            } else {
                XCTAssertEqual(node.next, nodes[index + 1])
            }
        }

    }
}
