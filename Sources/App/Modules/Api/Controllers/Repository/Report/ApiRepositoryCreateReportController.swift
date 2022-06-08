//
//  ApiRepositoryReportController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol ApiRepositoryCreateReportController: RepositoryController {
    associatedtype ReportCreateObject: Codable
    associatedtype ReportDetailObject: Content
    associatedtype DetailObject: InitializableById
    
    func beforeReport(_ req: Request) async throws
    func reportValidators() -> [AsyncValidator]
    func reportInput(_ req: Request, _ repository: Repository, _ report: Report, _ input: ReportCreateObject) async throws
    func reportApi(_ req: Request) async throws -> Response
    func reportResponse(_ req: Request, _ repository: Repository, _ report: Report) async throws -> ReportDetailObject
    func setupCreateReportRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryCreateReportController {
    func beforeReport(_ req: Request) async throws { }
    
    @AsyncValidatorBuilder
    func reportValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("title")
        KeyedContentValidator<String>.required("reason")
        KeyedContentValidator<UUID>.required("visibleDetailId")
    }
    
    func reportApi(_ req: Request) async throws -> Response {
        try await beforeReport(req)
        try await RequestValidator(reportValidators()).validate(req)
        
        let input = try req.content.decode(ReportCreateObject.self)
        let repository = try await repository(req)
        let report = Report()
        
        try await reportInput(req, repository, report, input)
        report.slug = try await report.generateSlug(with: .day, on: req.db)
        
        try await repository._$reports.create(report, on: req.db)
        return try await reportResponse(req, repository, report).encodeResponse(status: .created, for: req)
    }
    
    func setupCreateReportRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes.post("reports", use: reportApi)
    }
}

extension AppApi.Report.Detail: Content { }

extension ApiRepositoryCreateReportController where ReportCreateObject == AppApi.Report.Create, ReportDetailObject == AppApi.Report.Detail<DetailObject> {
    func beforeReport(_ req: Request) async throws {
        try await req.onlyForVerifiedUser()
    }
    
    func reportInput(_ req: Request, _ repository: Repository, _ report: Report, _ input: ReportCreateObject) async throws {
        /// Require user to be signed in
        let user = try req.auth.require(AuthenticatedUser.self)
        
        guard let currentlyVisibleDetail = try await Detail
            .query(on: req.db)
            .filter(\._$id == input.visibleDetailId)
            .filter(\._$repository.$id == repository.requireID())
            .first()
        else {
            throw Abort(.badRequest)
        }
        
        report.title = input.title
        report.reason = input.reason
        report._$visibleDetail.id = try currentlyVisibleDetail.requireID()
        report._$user.id = user.id
    }
    
    func reportResponse(_ req: Request, _ repository: Repository, _ report: Report) async throws -> ReportDetailObject {
        return try await .init(
            id: repository.requireID(),
            title: report.title,
            slug: report.slug,
            reason: report.reason,
            visibleDetail: DetailObject(id: report._$visibleDetail.id, db: req.db),
            status: report.status,
            reportId: report.requireID()
        )
    }
}
