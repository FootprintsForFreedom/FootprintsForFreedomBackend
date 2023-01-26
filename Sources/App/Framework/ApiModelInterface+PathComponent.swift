//
//  ApiModelInterface+PathComponent.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import AppApi

extension ApiModelInterface {
    /// The path id component for the model.
    ///
    /// The path id component usually represents the path id key with a leading colon.
    static var pathIdComponent: PathComponent { .init(stringLiteral: ":" + pathIdKey) }
}

