//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

public protocol ApiModuleInterface {
    static var pathKey: String { get }
}

public extension ApiModuleInterface {

    static var pathKey: String { String(describing: self).lowercased() }
}
