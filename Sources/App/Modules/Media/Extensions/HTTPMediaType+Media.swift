//
//  HTTPMediaType+Media.swift
//  
//
//  Created by niklhut on 12.05.22.
//

import Vapor
import AppApi

extension HTTPMediaType {
    func mediaGroup() -> Media.Detail.Group? {
        if let group = Media.Detail.Group.for("\(type)/\(subType)") {
            return group
        }
        return nil
    }
    
    var isValidForMedia: Bool {
        mediaGroup() != nil
    }
    
    func preferredFilenameExtension() -> String? {
        switch "\(type)/\(subType)" {
        case "video/quicktime": return "mov"
        case "video/mpeg": return "mpg"
        case "video/mp4": return "mp4"
        case "audio/mpeg": return "mp3"
        case "audio/vnd.wave", "audio/wave": return "wav"
        case "image/png": return "png"
        case "image/jpeg": return "jpeg"
        case "application/pdf": return "pdf"
        default: return nil
        }
    }
}
