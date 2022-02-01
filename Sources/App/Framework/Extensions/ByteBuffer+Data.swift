//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

public extension ByteBuffer {
    var data: Data? { getData(at: 0, length: readableBytes) }
}
