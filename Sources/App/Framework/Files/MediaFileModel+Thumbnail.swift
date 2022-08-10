//
//  MediaFileModel+Thumbnail.swift
//  
//
//  Created by niklhut on 09.08.22.
//

import Vapor
import SwiftGD
import ShellOut

extension MediaFileModel {
    private var maxSideLength: Int { 800 }
    private var thumbnailFilenameAppendix: String { "_thumbnail" }
    
    func createThumbnail(req: Request) async throws {
        guard req.application.environment != .testing else { return }
        switch self.group {
        case .video: try await createVideoThumbnail(req)
        case .audio: return
        case .image: try await createImageThumbnail(req)
        case .document: try await createDocumentThumbnail(req)
        }
    }
    
    func mediaFilePath(_ publicDirectory: String) -> String {
        publicDirectory + mediaDirectory
    }
    
    func mediaFilePath(_ req: Request) -> String {
        mediaFilePath(req.application.directory.publicDirectory)
    }
    
    func thumbnailFilePath(_ publicDirectory: String) -> String {
        var components = mediaDirectory.components(separatedBy: ".")
        guard components.count > 1 else {
            return mediaDirectory
        }
        components[components.count - 2].append(thumbnailFilenameAppendix)
        components[components.count - 1] = "jpg"
        return publicDirectory + components.joined(separator: ".")
    }
    
    private func thumbnailFilePath(_ req: Request) -> String {
        thumbnailFilePath(req.application.directory.publicDirectory)
    }
    
    private func createImageThumbnail(_ req: Request) async throws {
        let task = Task(priority: .utility) {
            let fileUrl = URL(fileURLWithPath: mediaFilePath(req))
            let thumbnailData = try scaleImage(keepingAspectRatio: true, maxSideLength: maxSideLength, data: Data(contentsOf: fileUrl))
            try thumbnailData.write(to: URL(fileURLWithPath: thumbnailFilePath(req)))
        }
        try await task.value
    }
    
    private func createVideoThumbnail(_ req: Request) async throws {
        let arguments = [
            "-ss",
            "00:00:01.00",
            "-i",
            mediaFilePath(req),
            "-filter:v",
            "'scale=800:800:force_original_aspect_ratio=decrease'",
            "-frames:v",
            "1",
            thumbnailFilePath(req)
        ]
        
        let task = Task(priority: .utility) {
            #if os(macOS)
            try shellOut(to: "/usr/local/bin/ffmpeg", arguments: arguments)
            return
            #elseif os(Linux)
            try shellOut(to: "/usr/bin/ffmpeg", arguments: arguments)
            return
            #else
            req.logger.log(level: .critical, "No runtime for creating video thumbnails provided. Thumbnails for videos cannot be created.")
            #endif
        }
        try await task.value
    }
    
    private func createDocumentThumbnail(_ req: Request) async throws {
        let arguments = [
            "-thumbnail",
            "'800x800>'",
            "-density 300",
            "-quality",
            "50",
            "-background",
            "white",
            "-alpha",
            "remove",
            "'\(mediaFilePath(req))[0]'",
            thumbnailFilePath(req)
        ]
        
        let task = Task(priority: .utility) {
            #if os(macOS)
            try shellOut(to: "/usr/local/bin/convert", arguments: arguments)
            return
            #elseif os(Linux)
            try shellOut(to: "/usr/bin/convert", arguments: arguments)
            return
            #else
            req.logger.log(level: .critical, "No runtime for creating document thumbnails provided. Thumbnails for documents cannot be created.")
            #endif
        }
        try await task.value
    }
    
    enum ImageResizingError: Swift.Error {
        case couldNotResizeImageToSpecifiedSize
    }
    
    private func scaleImage(keepingAspectRatio: Bool, maxSideLength: Int, data: Data, format: ExportableFormat = .jpg(quality: 50)) throws -> Data {
        var image = try Image(data: data)
        
        if image.size.width > maxSideLength || image.size.height > maxSideLength {
            let ratio = Double(image.size.width) / Double(image.size.height)
            
            var newWidth = image.size.width
            var newHeight = image.size.height
            
            if ratio > 1 && keepingAspectRatio {
                newWidth = maxSideLength
                newHeight = Int((Double(newWidth) / ratio).rounded())
            } else if ratio < 1 && keepingAspectRatio {
                newHeight = maxSideLength
                newWidth = Int((Double(newHeight) * ratio).rounded())
            } else {
                newWidth = maxSideLength
                newHeight = maxSideLength
            }
            
            guard let resizedImage = image.resizedTo(width: newWidth, height: newHeight) else {
                throw ImageResizingError.couldNotResizeImageToSpecifiedSize
            }
            image = resizedImage
        }
        
        let imageData = try image.export(as: format)
        return imageData
    }
}
