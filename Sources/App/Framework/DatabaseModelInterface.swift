//
//  DatabaseModelInterface.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

/// Streamlines creating database models.
public protocol DatabaseModelInterface: Fluent.Model where Self.IDValue == UUID {
    /// The module of the database model.
    associatedtype Module: ModuleInterface
    /// The identifier of the database model.
    ///
    /// The usually consists of the model name.
    static var identifier: String { get }
}

public extension DatabaseModelInterface {
    /// The schema name of the database model.
    ///
    /// The schema usually consists of the module identifier joined with the model identifier.
    static var schema: String { Module.identifier + "_" + identifier }
    
    static var identifier: String {
        String(describing: self).dropFirst(Module.identifier.count).dropLast(5).lowercased() + "s"
    }
}
