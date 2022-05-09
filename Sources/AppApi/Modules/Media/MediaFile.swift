//
//  MediaFile.swift
//  
//
//  Created by niklhut on 09.05.22.
//

import Foundation

public extension Media {
    struct File: Codable {
        public var filename: String
        public var data: Data
    }
}
