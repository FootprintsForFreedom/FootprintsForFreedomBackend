//
//  Timestamped.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol Timestamped: Fluent.Model {
    var createdAt: Date? { get }
    var updatedAt: Date? { get }
    var deletedAt: Date? { get }
}
