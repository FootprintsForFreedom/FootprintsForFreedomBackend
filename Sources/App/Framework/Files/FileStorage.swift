//
//  FileStorage.swift
//
//
//  Created by niklhut on 13.05.22.
//

import Vapor

struct FileStorage {
    /// Saves the data encoded into the body of the request to the filesystem at the specified path.
    /// - Parameters:
    ///   - req: The `Request`of which the body stream should be saved to the file system.
    ///   - path: The absolute path on the file system were the bodyStream should be saved.
    static func saveBodyStream(of req: Request, to path: String) async throws {
        try await saveBodyStream(of: req, to: path).get()
    }
    
    
    /// Saves the data encoded into the body of the request to the filesystem at the specified path.
    /// - Parameters:
    ///   - req: The `Request`of which the body stream should be saved to the file system.
    ///   - path: The absolute path on the file system were the bodyStream should be saved.
    private static func saveBodyStream(of req: Request, to path: String) throws -> EventLoopFuture<Void> {
        guard req.application.environment != .testing else { return req.eventLoop.future() }
        do {
            var sequential = req.eventLoop.makeSucceededFuture(())
            let directoryPath = URL(fileURLWithPath: path).deletingLastPathComponent()
            var isDirectory: ObjCBool = true
            if !FileManager.default.fileExists(atPath: directoryPath.absoluteString, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(at: directoryPath, withIntermediateDirectories: true)
            }
            return req.application.fileio
                .openFile(path: path, mode: .write, flags: .allowFileCreation(), eventLoop: req.eventLoop)
                .flatMap { handle -> EventLoopFuture<Void> in
                    let promise = req.eventLoop.makePromise(of: Void.self)
                    
                    req.body.drain {
                        switch $0 {
                        case .buffer(let chunk):
                            sequential = sequential.flatMap {
                                req.application.fileio.write(fileHandle: handle, buffer: chunk, eventLoop: req.eventLoop)
                            }
                            return sequential
                        case .error(let error):
                            promise.fail(error)
                            return req.eventLoop.future(error: error)
                        case .end:
                            promise.succeed(())
                            return req.eventLoop.makeSucceededFuture(())
                        }
                    }
                    
                    return promise.futureResult
                        .flatMap {
                            // check there actually is a data in the file otherwise delete the file
                            req.application.fileio.readFileSize(fileHandle: handle, eventLoop: req.eventLoop).flatMapThrowing { byteCount in
                                if byteCount == 0 {
                                    throw Abort(.badRequest)
                                }
                            }
                            .transform(to: sequential)
                        }
                        .always { result in
                            _ = try? handle.close()
                        }
                }
        } catch {
            // delete the file if an error occurs while uploading
            // namely the file stream ended unexpectedly which means the upload was cancelled
            // avoids having corrupted files in the filesystem
            try delete(at: path)
            throw error
        }
    }
    
    /// Deletes the file at the specified path from the file system
    /// - Parameter path: The absolute path of the file on the file system
    static func delete(at path: String) throws  {
        guard exists(at: path) else {
            return
        }
        try FileManager.default.removeItem(atPath: path)
    }
    
    /// Checks if a file at the given path exists.
    /// - Parameter path: The path at which should be checked if a file exists.
    /// - Returns: A bool wether or not a file exists.
    static func exists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
