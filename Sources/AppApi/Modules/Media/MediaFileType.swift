//
//  MediaFileType.swift
//  
//
//  Created by niklhut on 16.02.22.
//

import Foundation

public extension Media.Detail {
    /// Used to categorize media file types
    enum FileType: String, Codable, CaseIterable, ApiModelInterface {
        public typealias Module = Media
        
        /// Used for video files.
        ///
        /// Supported mime types are:
        /// - video/quicktime
        /// - video/mpeg
        /// - video/mp4
        case video
        
        /// Used for audio files.
        ///
        /// Supported mime types are:
        /// - audio/mpeg
        /// - audio/wav
        /// - audio/vnd.wave
        case audio
        
        /// Used for image files.
        ///
        /// Supported mime types are:
        /// - image/png
        /// - image/jpeg
        case image
        
        /// Used for document files.
        ///
        /// Supported mime types are:
        /// - application/pdf
        case document
        
        /// Allowed mime types for the respective file types.
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
        
        /// Gets the media group for a mime type
        /// - Parameter fileType: The mime type of the file.
        /// - Returns: A media group or nil if the mime type is not supported.
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
