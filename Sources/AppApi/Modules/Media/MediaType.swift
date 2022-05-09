//
//  MediaType.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Foundation

public extension Media.Media {
    enum Group: String, Codable, CaseIterable, ApiModelInterface {
        public typealias Module = Waypoint
        
        case video, audio, document
    }
}
