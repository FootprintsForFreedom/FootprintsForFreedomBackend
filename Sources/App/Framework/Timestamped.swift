//
//  Timestamped.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

/// Represents a model with timestamps.
public protocol Timestamped where Self: Fluent.Model {
    /// The date the model was created.
    var createdAt: Date? { get set }
    
    /// The date the model was last updated.
    var updatedAt: Date? { get set }
    /// The date the model was last updated.
    var _$updatedAt: TimestampProperty<Self, DefaultTimestampFormat> { get }
    
    /// The date the model was deleted.
    var deletedAt: Date? { get set }
    /// The date the model was deleted.
    var _$deletedAt: TimestampProperty<Self, DefaultTimestampFormat> { get }
}
