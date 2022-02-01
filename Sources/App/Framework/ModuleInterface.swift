//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public protocol ModuleInterface {
    
    static var identifier: String { get }

    func boot(_ app: Application) throws
    func setUp(_ app: Application) throws
}

public extension ModuleInterface {
    func boot(_ app: Application) throws {}
    func setUp(_ app: Application) throws {}

    static var identifier: String { String(describing: self).dropLast(6).lowercased() }
    
}
