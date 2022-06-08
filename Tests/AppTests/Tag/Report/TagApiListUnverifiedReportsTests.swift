//
//  TagApiListUnverifiedReportsTests.swift
//  
//
//  Created by niklhut on 08.06.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

final class TagApiListUnverifiedReportsTests: AppTestCase, TagTest {
    func testSuccessfulListUnverifiedReportsListsUnverifiedReports() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag()
        let title = "I don't like this \(UUID())"
        let report = try await TagReportModel(
            status: .pending,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: tag.detail.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        let reportsCount = try await TagReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports should return unverified reports")
            .get(tagPath.appending("\(tag.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Report.List>.self) { content in
                XCTAssert(content.items.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testSuccessfulListUnverifiedReportsDoesNotListVerifiedReports() async throws {
        let moderatorToken = try await getToken(for: .moderator)
        let tag = try await createNewTag()
        let title = "I don't like this \(UUID())"
        let report = try await TagReportModel(
            status: .verified,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: tag.detail.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        let reportsCount = try await TagReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports should not return verified reports")
            .get(tagPath.appending("\(tag.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(moderatorToken)
            .expect(.ok)
            .expect(.json)
            .expect(Page<Report.List>.self) { content in
                XCTAssert(!content.items.contains { $0.id == tag.repository.id })
            }
            .test()
    }
    
    func testListUnverifiedReportsAsUserFails() async throws {
        let token = try await getToken(for: .user)
        let tag = try await createNewTag()
        let title = "I don't like this \(UUID())"
        let report = try await TagReportModel(
            status: .pending,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: tag.detail.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        let reportsCount = try await TagReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports as user should fail")
            .get(tagPath.appending("\(tag.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .bearerToken(token)
            .expect(.forbidden)
            .test()
    }
    
    func testListUnverifiedReportsWithoutTokenFails() async throws {
        let tag = try await createNewTag()
        let title = "I don't like this \(UUID())"
        let report = try await TagReportModel(
            status: .pending,
            title: title,
            slug: title.slugify(),
            reason: "Just because",
            visibleDetailId: tag.detail.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: getUser(role: .user).requireID()
        )
        try await report.create(on: app.db)
        
        let reportsCount = try await TagReportModel.query(on: app.db).count()
        
        try app
            .describe("List unverified reports without token should fail")
            .get(tagPath.appending("\(tag.repository.requireID())/reports/unverified/?per=\(reportsCount)"))
            .expect(.unauthorized)
            .test()
    }
}
