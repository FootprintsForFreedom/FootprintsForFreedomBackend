//
//  WaypointTest+Report.swift
//  
//
//  Created by niklhut on 13.06.22.
//

@testable import App
import XCTVapor
import Fluent

extension WaypointTest {
    func createNewWaypointReport(
        waypoint: (repository: WaypointRepositoryModel, detail: WaypointDetailModel, location: WaypointLocationModel),
        verifiedAt: Date? = nil,
        title: String = "New report title \(UUID())",
        reason: String = "Just because",
        userId: UUID? = nil
    ) async throws -> WaypointReportModel {
        var userId: UUID! = userId
        if userId == nil {
            userId = try await getUser(role: .user).requireID()
        }
        
        let report = try WaypointReportModel(
            verifiedAt: verifiedAt,
            title: title,
            slug: title.slugify(),
            reason: reason,
            visibleDetailId: waypoint.detail.requireID(),
            repositoryId: waypoint.repository.requireID(),
            userId: userId
        )
        try await report.create(on: app.db)
        
        return report
    }
}
