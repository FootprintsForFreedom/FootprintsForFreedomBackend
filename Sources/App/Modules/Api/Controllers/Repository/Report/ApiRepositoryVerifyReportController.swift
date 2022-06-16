//
//  ApiRepositoryVerifyReportController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol ApiRepositoryVerifyReportController: RepositoryController where DatabaseModel: Reportable {
    associatedtype ReportDetailObject: Content
    associatedtype DetailObject: InitializableById
    
    var reportPathIdKey: String { get }
    var reportPathIdComponent: PathComponent { get }
    
    func beforeVerifyReport(_ req: Request) async throws
    func verifyReport(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws
    func verifyReportApi(_ req: Request) async throws -> ReportDetailObject
    func verifyReportOutput(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws -> ReportDetailObject
    func setupVerifyReportRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryVerifyReportController {
    var reportPathIdKey: String { "reportId" }
    var reportPathIdComponent: PathComponent { .init(stringLiteral: ":" + reportPathIdKey) }
    
    func beforeVerifyReport(_ req: Request) async throws { }
    
    func verifyReport(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws {
        report.status = .verified
        try await report.update(on: req.db)
    }
    
    func verifyReportApi(_ req: Request) async throws -> ReportDetailObject {
        try await beforeVerifyReport(req)
        
        let repository = try await repository(req)
        
        guard
            let reportIdString = req.parameters.get(reportPathIdKey),
            let reportId = UUID(uuidString: reportIdString)
        else {
            throw Abort(.badRequest)
        }
        
        guard let report = try await Report
            .query(on: req.db)
            .filter(\._$id == reportId)
            .filter(\._$repository.$id == repository.requireID())
            .filter(\._$status == .pending)
            .first()
        else {
            throw Abort(.badRequest)
        }
        
        try await verifyReport(req, repository, report)
        
        return try await verifyReportOutput(req, repository, report)
    }
    
    func setupVerifyReportRoutes(_ routes: RoutesBuilder) {
        let baseRoutes = getBaseRoutes(routes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent)
        existingModelRoutes
            .grouped("reports")
            .grouped("verify")
            .grouped(reportPathIdComponent)
            .post(use: verifyReportApi)
        
    }
}

extension ApiRepositoryVerifyReportController where ReportDetailObject == AppApi.Report.Detail<DetailObject> {
    func beforeVerifyReport(_ req: Request) async throws {
        try await req.onlyFor(.moderator)
    }
    
    func verifyReportOutput(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws -> ReportDetailObject {
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
