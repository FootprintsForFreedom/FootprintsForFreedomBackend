//
//  MediaGroup.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Foundation

public extension Media.Media {
    enum Group: String, Codable, CaseIterable, ApiModelInterface {
        public typealias Module = Waypoint
        
        case video, audio, image, document
        
        public var allowedMimeTypes: [String] {
            switch self {
            case .video:
                return ["video/quicktime", "video/mpeg", "video/mp4"]
            case .audio:
                return ["audio/mpeg", "audio/wav", "audio/vnd.wave"]
            case .image:
                return ["image/png", "image/jpeg"]
            case .document:
                return ["application/pdf"]
            }
        }
        
        public static func `for`(_ fileType: String) -> Self? {
            for group in Self.allCases {
                if group.allowedMimeTypes.contains(fileType) {
                    return group
                }
            }
            return nil
        }
    }
}
