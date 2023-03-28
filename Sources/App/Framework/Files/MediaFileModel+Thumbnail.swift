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
    /// The appendix which should be added to the original filename to indicate it is a thumbnail.
    private static var thumbnailFilenameAppendix: String { "_thumbnail" }
    
    /// Gets the relative file path of the thumbnail for a given media file path.
    /// - Parameter relativeMediaFilePath: The media for which to get the thumbnail file path.
    /// - Returns: The relative thumbnail file path for the media file. 
    static func relativeThumbnailFilePath(for relativeMediaFilePath: String) -> String {
        var components = relativeMediaFilePath.components(separatedBy: ".")
        guard components.count > 1 else {
            return relativeMediaFilePath
        }
        components[components.count - 2].append(thumbnailFilenameAppendix)
        components[components.count - 1] = "jpg"
        return components.joined(separator: ".")
    }
    
    /// The maximum length of the longer side of the thumbnail.
    private var maxThumbnailSideLength: Int { 800 }
    
    /// Creates a thumbnail for this media file on the request.
    ///
    /// Thumbnails can only be created for images, videos and documents. Thumbnails for audio files are not supported.
    ///
    /// - Parameter req: The request on which to create the thumbnail.
    func createThumbnail(req: Request) async throws {
        guard req.application.environment != .testing else { return }
        switch self.group {
        case .video: try await createVideoThumbnail(req)
        case .audio: return
        case .image: try await createImageThumbnail(req)
        case .document: try await createDocumentThumbnail(req)
        }
    }
    
    /// The file path for this media file.
    /// - Parameter publicDirectory: The public directory of the application.
    /// - Returns: The file path of this media file.
    func absoluteMediaFilePath(_ publicDirectory: String) -> String {
        publicDirectory + relativeMediaFilePath
    }
    
    /// The file path for this media file.
    /// - Parameter req: The request which can determine the public directory of the application.
    /// - Returns: The file path for this media.
    func absoluteMediaFilePath(_ req: Request) -> String {
        absoluteMediaFilePath(req.application.directory.publicDirectory)
    }
    
    /// The relative file path of the thumbnail.
    var relativeThumbnailFilePath: String {
        Self.relativeThumbnailFilePath(for: relativeMediaFilePath)
    }
    
    /// The file path for the thumbnail of this media.
    /// - Parameter publicDirectory: The public directory of the application.
    /// - Returns: The file path for the thumbnail of this media.
    func absoluteThumbnailFilePath(_ publicDirectory: String) -> String {
        publicDirectory + relativeThumbnailFilePath
    }
    
    /// The file path for the thumbnail of this media.
    /// - Parameter req: The request which can determine the public directory of the application
    /// - Returns: The file path for the thumbnail of this media.
    private func absoluteThumbnailFilePath(_ req: Request) -> String {
        absoluteThumbnailFilePath(req.application.directory.publicDirectory)
    }
    
    /// Creates a thumbnail for an image.
    /// - Parameter req: The request on which to create the thumbnail.
    private func createImageThumbnail(_ req: Request) async throws {
        /// Perform in a task to not block the main thread.
        let task = Task(priority: .utility) {
            let fileUrl = URL(fileURLWithPath: absoluteMediaFilePath(req))
            let inputFormat: ImportableFormat = {
                switch relativeMediaFilePath.split(separator: ".").last {
                case "png": return .png
                case "jpg", "jpeg": return .jpg
                default: return .any
                }
            }()
            let thumbnailData = try scaleImage(keepingAspectRatio: true, maxSideLength: maxThumbnailSideLength, data: Data(contentsOf: fileUrl), inputFormat: inputFormat)
            try thumbnailData.write(to: URL(fileURLWithPath: absoluteThumbnailFilePath(req)))
        }
        try await task.value
    }
    
    /// Creates a thumbnail for a video.
    /// - Parameter req: The request on which to create the thumbnail.
    private func createVideoThumbnail(_ req: Request) async throws {
        /// Perform in a task to not block the main thread.
        let task = Task(priority: .utility) {
            let arguments = [
                "-ss",
                "00:00:01.00",
                "-i",
                absoluteMediaFilePath(req),
                "-filter:v",
                "'scale=800:800:force_original_aspect_ratio=decrease'",
                "-frames:v",
                "1",
                absoluteThumbnailFilePath(req)
            ]
            
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
    
    /// Creates a thumbnail for a pdf document.
    /// - Parameter req: The request on which to create the thumbnail.
    private func createDocumentThumbnail(_ req: Request) async throws {
        /// Perform in a task to not block the main thread.
        let task = Task(priority: .utility) {
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
                "'\(absoluteMediaFilePath(req))[0]'",
                absoluteThumbnailFilePath(req)
            ]
            
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
    
    /// Error thrown when image resizing fails.
    enum ImageResizingError: Swift.Error {
        /// The image could not be resized to the specified size.
        case couldNotResizeImageToSpecifiedSize
    }
    
    /// Scales and converts an image.
    /// - Parameters:
    ///   - keepingAspectRatio: Wether tho keep the original aspect ratio.
    ///   - maxSideLength: The maximum side length of the image.
    ///   - data: The image data.
    ///   - inputFormat: The input format of the image.
    ///   - outputFormat: The desired output format of the image.
    /// - Returns: The data of the scaled and converted image.
    private func scaleImage(keepingAspectRatio: Bool, maxSideLength: Int, data: Data, inputFormat: ImportableFormat, outputFormat: ExportableFormat = .jpg(quality: 50)) throws -> Data {
        var image = try Image(data: data, as: inputFormat)
        
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
        
        let imageData = try image.export(as: outputFormat)
        return imageData
    }
}
