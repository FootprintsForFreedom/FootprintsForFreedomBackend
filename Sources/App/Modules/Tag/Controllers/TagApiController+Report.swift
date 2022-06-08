//
//  TagApiController+Report.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

extension Tag.Detail.Detail: InitializableById {
    init?(id: UUID?, db: Database) async throws {
        guard let id, let detail = try await TagDetailModel.find(id, on: db) else {
            return nil
        }
        try await detail.$language.load(on: db)
        self = Self.publicDetail(
            id: detail.$repository.id,
            title: detail.title,
            keywords: detail.keywords,
            slug: detail.slug,
            languageCode: detail.language.languageCode
        )
    }
}

extension TagApiController: ApiRepositoryReportController {
    typealias ReportCreateObject = Report.Create
    typealias ReportDetailObject = Report.Detail<DetailObject>
    typealias ReportListObject = Report.List
    typealias DetailObject = Tag.Detail.Detail
}
