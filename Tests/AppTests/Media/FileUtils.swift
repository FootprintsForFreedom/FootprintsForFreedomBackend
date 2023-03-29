//
//  FileUtils.swift
//  
//
//  Created by niklhut on 29.03.23.
//

import Vapor

struct FileUtils {
    struct TestFile {
        let mimeType: String
        let filename: String
        let fileExtension: String
    }
    
    static let testFiles: [TestFile] =  [
        .init(mimeType: "image/png", filename: "Logo_groß", fileExtension: "png"),
        .init(mimeType: "image/jpeg", filename: "Logo_groß", fileExtension: "jpg"),
        .init(mimeType: "video/quicktime", filename: "1280", fileExtension: "mov"),
        .init(mimeType: "video/mp4", filename: "640", fileExtension: "mp4"),
        .init(mimeType: "audio/mpeg", filename: "samplemp3", fileExtension: "mp3"),
        .init(mimeType: "audio/vnd.wave", filename: "Wav_868kb", fileExtension: "wav"),
        .init(mimeType: "application/pdf", filename: "SamplePdf", fileExtension: "pdf")
    ]
    
    static let testImage = testFiles.first!
    
    static func testFile(excludedFileTypes: [Media.Detail.FileType]) -> TestFile? {
        let excludedMimeTypes = excludedFileTypes.flatMap(\.allowedMimeTypes)
        let allowedTestFiles = testFiles.filter { !excludedMimeTypes.contains($0.mimeType) }
        return allowedTestFiles.randomElement()
    }
    
    static func testFile(excludedFileType: Media.Detail.FileType) -> TestFile {
        testFile(excludedFileTypes: [excludedFileType])!
    }
    
    static func data(for resource: String, withExtension fileExtension: String) throws -> Data {
        let fileURL = Bundle.module.url(forResource: resource, withExtension: fileExtension)!
        let data = try Data(contentsOf: fileURL)
        return data
    }
    
    static func data(for testFile: TestFile) throws -> ByteBuffer {
        try ByteBuffer(data: data(for: testFile.filename, withExtension: testFile.fileExtension))
    }
}
