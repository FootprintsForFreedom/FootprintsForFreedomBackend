//
//  TagApiVerifyReportTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiVerifyReportTests: AppTestCase, TagTest {
    func testSuccessfulVerifyReport() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag()
        let report = try await createNewTagReport(tag: tag)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(tagPath.appending("\(tag.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Report.Detail<Tag.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, report.title)
                XCTAssertContains(content.slug, report.title.slugify())
                XCTAssertEqual(content.reason, report.reason)
                XCTAssertNotNil(content.visibleDetail)
                if let visibleDetail = content.visibleDetail {
                    XCTAssertEqual(visibleDetail.id, tag.repository.id)
                    XCTAssertEqual(visibleDetail.title, tag.detail.title)
                    XCTAssertEqual(visibleDetail.slug, tag.detail.slug)
                    XCTAssertEqual(visibleDetail.keywords, tag.detail.keywords)
                    XCTAssertEqual(visibleDetail.languageCode, tag.detail.language.languageCode)
                    XCTAssertNil(visibleDetail.status)
                    XCTAssertNotNil(visibleDetail.detailId)
                }
            }
            .test()
    }
    
    func testSuccessfulVerifyReportWithDeletedVisbleDetail() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag()
        let report = try await createNewTagReport(tag: tag)
        try await tag.detail.delete(force: true, on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(tagPath.appending("\(tag.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Report.Detail<Tag.Detail.Detail>.self) { content in
                XCTAssertEqual(content.title, report.title)
                XCTAssertContains(content.slug, report.title.slugify())
                XCTAssertEqual(content.reason, report.reason)
                XCTAssertNil(content.visibleDetail)
            }
            .test()
    }
    
    func testVerifyReportAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let tag = try await createNewTag()
        let report = try await createNewTagReport(tag: tag)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as user should fail")
            .post(tagPath.appending("\(tag.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testVerifyReportWithoutTokenFails() async throws {
        let tag = try await createNewTag()
        let report = try await createNewTagReport(tag: tag)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report without token should fail")
            .post(tagPath.appending("\(tag.repository.requireID())/reports/verify/\(report.requireID())"))
            .expect(.unauthorized)
            .test()
    }
    
    func testVerifyReportWithAlreadyVerifiedReportFails() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag()
        let report = try await createNewTagReport(tag: tag, status: .verified)
        try await tag.detail.$language.load(on: app.db)
        
        try app
            .describe("Verify report as moderator should be successful and return ok")
            .post(tagPath.appending("\(tag.repository.requireID())/reports/verify/\(report.requireID())"))
            .bearerToken(moderatorToken)
            .expect(.badRequest)
            .test()
    }
}
