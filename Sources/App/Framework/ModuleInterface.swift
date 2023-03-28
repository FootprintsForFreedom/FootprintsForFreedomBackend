//
//  ModuleInterface.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

/// Streamlines creating modules.
public protocol ModuleInterface {
    /// The module identifier.
    ///
    /// The module identifier usually consists of the module name.
    static var identifier: String { get }
    
    /// Boots the module with all implemented migrations, hooks and routes.
    /// - Parameter app: The app on which the boot the module.
    func boot(_ app: Application) throws
    /// Sets up all hooked routes after the module has been booted.
    /// - Parameter app: The app on which to set up the module.
    func setUp(_ app: Application) throws
}

public extension ModuleInterface {
    func boot(_ app: Application) throws {}
    func setUp(_ app: Application) throws {}
    
    static var identifier: String { String(describing: self).dropLast(6).lowercased() }
    
}
