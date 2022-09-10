//
//  WaypointApiController+Report.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

extension Waypoint.Detail.Detail: InitializableById {
    init?(id: UUID?, db: Database) async throws {
        guard let id, let detail = try await WaypointDetailModel.find(id, on: db) else {
            return nil
        }
        let repository = try await detail.$repository.get(on: db)
        guard let location = try await repository.$locations.firstFor(needsToBeVerified: false, on: db) else {
            throw Abort(.badRequest)
        }
        try await detail.$language.load(on: db)
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: detail.language.languageCode, on: db)
        
        self = try await .init(
            id: repository.requireID(),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            location: location.location,
            tags: repository.tagList(for: allLanguageCodesByPriority, on: db),
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(db),
            detailId: detail.requireID(),
            locationId: location.requireID()
        )
    }
}

extension WaypointApiController: ApiRepositoryReportController {
    typealias ReportCreateObject = Report.Create
    typealias ReportDetailObject = Report.Detail<DetailObject>
    typealias ReportListObject = Report.List
    typealias DetailObject = Waypoint.Detail.Detail
}
