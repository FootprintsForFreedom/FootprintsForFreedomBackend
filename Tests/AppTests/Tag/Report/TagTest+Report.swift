//
//  TagTest+Report.swift
//  
//
//  Created by niklhut on 13.06.22.
//

@testable import App
import XCTVapor
import Fluent

extension TagTest {
    func createNewTagReport(
        tag: (repository: TagRepositoryModel, detail: TagDetailModel),
        verifiedAt: Date? = nil,
        title: String = "New report title \(UUID())",
        reason: String = "Just because",
        userId: UUID? = nil
    ) async throws -> TagReportModel {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let report = try TagReportModel(
            verifiedAt: verifiedAt,
            title: title,
            slug: title.slugify(),
            reason: reason,
            visibleDetailId: tag.detail.requireID(),
            repositoryId: tag.repository.requireID(),
            userId: userId
        )
        try await report.create(on: app.db)
        
        return report
    }
}
