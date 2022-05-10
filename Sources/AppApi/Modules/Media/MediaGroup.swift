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
        
        public var allowedFileExtensions: [String] {
            // file extensions for the groups according to their mime types
            // see https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types
            // and https://developer.mozilla.org/en-US/docs/Web/Media/Formats
            switch self {
            case .video:
                // video/quicktime, video/mpeg, video/mp4
                return ["mov", "mpg", "mpeg", "mpe", "m75", "m15", "mp4", "mpg4"]
            case .audio:
                // audio/mpeg, audio/wav
                return ["mp3", "mpga", "wav", "wave", "bwf"]
            case .image:
                // image/png, image/jpeg
                return ["png", "jpg", "jpeg", "jpe"]
            case .document:
                // application/pdf
                return ["pdf"]
            }
        }
        
        public static func `for`(_ fileExtension: String) -> Self? {
            for group in Self.allCases {
                if group.allowedFileExtensions.contains(fileExtension) {
                    return group
                }
            }
            return nil
        }
    }
}
