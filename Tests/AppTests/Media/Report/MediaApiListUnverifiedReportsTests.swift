//
//  MediaApiListUnverifiedReportsTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class MediaApiListUnverifiedReportsTests: AppTestCase, MediaTest {
    func testSuccessfulListUnverifiedReportsListsUnverifiedReports() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media)
        let reportsCount = try await MediaReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports should return unverified reports")
            .get(mediaPath.appending("\(media.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Report.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == report.id })
            }
            .test()
    }
    
    func testSuccessfulListUnverifiedReportsDoesNotListVerifiedReports() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let media = try await createNewMedia()
        let report = try await createNewMediaReport(media: media, verifiedAt: Date())
        let reportsCount = try await MediaReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports should not return verified reports")
            .get(mediaPath.appending("\(media.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Report.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == report.id })
            }
            .test()
    }
    
    func testListUnverifiedReportsAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let media = try await createNewMedia()
        let _ = try await createNewMediaReport(media: media)
        let reportsCount = try await MediaReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports as user should fail")
            .get(mediaPath.appending("\(media.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedReportsWithoutTokenFails() async throws {
        let media = try await createNewMedia()
        let _ = try await createNewMediaReport(media: media)
        let reportsCount = try await MediaReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports without token should fail")
            .get(mediaPath.appending("\(media.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .expect(.unauthorized)
            .test()
    }
}
