//
//  Node.swift
//  
//
//  Created by niklhut on 13.02.22.
//

import Foundation

protocol Node: AnyObject, Equatable where NodeObject.NodeObject == NodeObject, NodeObject.Element == Element {
    associatedtype Element
    associatedtype NodeObject: Node
    
    var value: Element { get set }
    var next: NodeObject? { get set }
    var previous: NodeObject? { get set }
    
    init(value: Element) throws
}
