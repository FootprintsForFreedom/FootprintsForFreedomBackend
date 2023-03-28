//
//  MediaTest+Report.swift
//  
//
//  Created by niklhut on 13.06.22.
//

@testable import App
import XCTVapor
import Fluent

extension MediaTest {
    func createNewMediaReport(
        media: (repository: MediaRepositoryModel, detail: MediaDetailModel, file: MediaFileModel),
        verifiedAt: Date? = nil,
        title: String = "New report title \(UUID())",
        reason: String = "Just because",
        userId: UUID? = nil
    ) async throws -> MediaReportModel {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let report = try MediaReportModel(
            verifiedAt: verifiedAt,
            title: title,
            slug: title.slugify(),
            reason: reason,
            visibleDetailId: media.detail.requireID(),
            repositoryId: media.repository.requireID(),
            userId: userId
        )
        try await report.create(on: app.db)
        
        return report
    }
}
