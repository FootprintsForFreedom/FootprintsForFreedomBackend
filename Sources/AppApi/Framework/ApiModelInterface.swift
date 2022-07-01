//
//  ApiModelInterface.swift
//  
//
//  Created by niklhut on 01.02.22.
//

/// An interface for api models.
public protocol ApiModelInterface {
    /// The ``ApiModuleInterface`` to which the model belongs.
    associatedtype Module: ApiModuleInterface
    
    /// The model's path key.
    static var pathKey: String { get }
    /// The model's path id key.
    static var pathIdKey: String { get }
}

public extension ApiModelInterface {
    static var pathKey: String { String(describing: self).lowercased() + "s" }
    static var pathIdKey: String { String(describing: self).lowercased() + "Id" }
}

