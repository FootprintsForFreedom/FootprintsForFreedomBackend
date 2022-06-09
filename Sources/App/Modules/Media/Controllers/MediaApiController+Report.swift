//
//  MediaApiController+Report.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

extension Media.Detail.Detail: InitializableById {
    init?(id: UUID?, db: Database) async throws {
        guard let id, let detail = try await MediaDetailModel.find(id, on: db) else {
            return nil
        }
        let repository = try await detail.$repository.get(on: db)
        try await detail.$language.load(on: db)
        try await detail.$media.load(on: db)
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: detail.language.languageCode, on: db)
        
        self = try await Self.publicDetail(
            id: repository.requireID(),
            languageCode: detail.language.languageCode,
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            source: detail.source,
            group: detail.media.group,
            filePath: detail.media.mediaDirectory,
            tags: repository.tagList(for: allLanguageCodesByPriority, on: db)
        )
    }
}

extension MediaApiController: ApiRepositoryReportController {
    typealias ReportCreateObject = Report.Create
    typealias ReportDetailObject = Report.Detail<DetailObject>
    typealias ReportListObject = Report.List
    typealias DetailObject = Media.Detail.Detail
}