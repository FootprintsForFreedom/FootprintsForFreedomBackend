//
//  MediaApiVerifyReportTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiVerifyReportTests: AppTestCase, MediaTest {
    func testSuccessfulVerifyReport() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media)
        try await media.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(mediaPath.appending("\(media.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Report.Detail<Media.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, report.title)
                XCTAssertContains(content.slug, report.title.slugify())
                XCTAssertEqual(content.reason, report.reason)
                XCTAssertNotNil(content.visibleDetail)
                if let visibleDetail = content.visibleDetail {
                    XCTAssertEqual(visibleDetail.id, media.repository.id)
                    XCTAssertEqual(visibleDetail.title, media.detail.title)
                    XCTAssertEqual(visibleDetail.slug, media.detail.slug)
                    XCTAssertEqual(visibleDetail.detailText, media.detail.detailText)
                    XCTAssertEqual(visibleDetail.languageCode, media.detail.language.languageCode)
                    XCTAssertEqual(visibleDetail.fileType, media.file.fileType)
                    XCTAssertEqual(visibleDetail.filePath, media.file.relativeMediaFilePath)
                    XCTAssertNotNil(visibleDetail.detailId)
                }
            }
            .test()
    }
    
    func testSuccessfulVerifyReportWithDeletedVisbleDetail() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media)
        try await media.detail.delete(force: true, on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(mediaPath.appending("\(media.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Report.Detail<Media.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, report.title)
                XCTAssertContains(content.slug, report.title.slugify())
                XCTAssertEqual(content.reason, report.reason)
                XCTAssertNil(content.visibleDetail)
            }
            .test()
    }
    
    func testVerifyReportAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media)
        try await media.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as user should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyReportWithoutTokenFails() async throws {
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media)
        try await media.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report without token should fail")
            .post(mediaPath.appending("\(media.repository.requireID())/reports/verify/\(report.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyReportWithAlreadyVerifiedReportFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media, verifiedAt: Date())
        try await media.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(mediaPath.appending("\(media.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
