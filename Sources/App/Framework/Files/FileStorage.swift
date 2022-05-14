//
//  FileStorage.swift
//
//
//  Created by niklhut on 13.05.22.
//

import Vapor

struct FileStorage {
    static func saveBodyStream(of req: Request, to path: String) async throws {
        do {
            var sequential = req.eventLoop.makeSucceededFuture(())
            try await req.application.fileio
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
                            // check there actually is a data in the file otherwise delte the file
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
                .get()
        } catch {
            // delte the file if an error occurs while uploading
            // namely the file stream ended unexpectedly which means the upload was cancelled
            // avoid having corrupted files in the filesystem
            try delete(at: path)
            throw error
        }
    }
    
    static func delete(at path: String) throws  {
        guard exists(at: path) else {
            return
        }
        try FileManager.default.removeItem(atPath: path)
    }
    
    static func exists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
}
