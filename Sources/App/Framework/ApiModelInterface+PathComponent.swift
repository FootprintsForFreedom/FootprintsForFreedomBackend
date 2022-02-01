//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension ApiModelInterface {

    static var pathIdComponent: PathComponent { .init(stringLiteral: ":" + pathIdKey) }
}

