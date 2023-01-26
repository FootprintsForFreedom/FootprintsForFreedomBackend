//
//  MediaApiController+Report.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent
import AppApi

extension Media.Detail.Detail: InitializableById {
    init?(id: UUID?, db: Database) async throws {
        guard let id, let detail = try await MediaDetailModel.find(id, on: db) else {
            return nil
        }
        let repository = try await detail.$repository.get(on: db)
        try await detail.$language.load(on: db)
        try await detail.$media.load(on: db)
        
        let allLanguageCodesByPriority = try await LanguageModel.languageCodesByPriority(preferredLanguageCode: detail.language.languageCode, on: db)
        
        self = try await .init(
            id: repository.requireID(),
            languageCode: detail.language.languageCode,
            availableLanguageCodes: repository.availableLanguageCodes(db),
            title: detail.title,
            slug: detail.slug,
            detailText: detail.detailText,
            source: detail.source,
            group: detail.media.group,
            filePath: detail.media.relativeMediaFilePath,
            tags: repository.tagList(for: allLanguageCodesByPriority, on: db),
            detailId: detail.requireID()
        )
    }
}

extension MediaApiController: ApiRepositoryReportController {
    typealias ReportCreateObject = Report.Create
    typealias ReportDetailObject = Report.Detail<DetailObject>
    typealias ReportListObject = Report.List
    typealias DetailObject = Media.Detail.Detail
}
