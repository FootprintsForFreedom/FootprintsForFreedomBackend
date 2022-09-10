//
//  ApiRepositoryVerifyReportController.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

/// Streamlines verifying repository reports.
protocol ApiRepositoryVerifyReportController: RepositoryController where DatabaseModel: Reportable {
    /// The report detail object content
    associatedtype ReportDetailObject: Content
    /// The database detail object for the repository.
    associatedtype DetailObject: InitializableById
    
    /// The path id key for the report id.
    var reportPathIdKey: String { get }
    /// The path id component for the report id.
    var reportPathIdComponent: PathComponent { get }
    
    /// Action performed prior to verifying the report.
    /// - Parameter req: The request on which the report will be verified.
    func beforeVerifyReport(_ req: Request) async throws
    
    /// Verifies the report on the database.
    /// - Parameters:
    ///   - req: The request on which to verify the report.
    ///   - repository: The repository to which the report belongs.
    ///   - report: The report to be verified.
    func verifyReport(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws
    
    /// The verify report api action.
    /// - Parameter req: The request on which to verify the report.
    /// - Returns: A report detail object for the verified report.
    func verifyReportApi(_ req: Request) async throws -> ReportDetailObject
    
    /// The report detail response which will be returned
    /// - Parameters:
    ///   - req: The request on which the report was verified.
    ///   - repository: The repository to which the report belongs.
    ///   - report: The report which was verified.
    /// - Returns: A report detail object for the verified report.
    func verifyReportOutput(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws -> ReportDetailObject
    
    /// Sets up the verify report routes.
    /// - Parameter routes: The routes on which to setup the verify report routes.
    func setupVerifyReportRoutes(_ routes: RoutesBuilder)
}

extension ApiRepositoryVerifyReportController {
    var reportPathIdKey: String { "reportId" }
    var reportPathIdComponent: PathComponent { .init(stringLiteral: ":" + reportPathIdKey) }
    
    func beforeVerifyReport(_ req: Request) async throws { }
    
    func verifyReport(_ req: Request, _ repository: DatabaseModel, _ report: Report) async throws {
        report.verifiedAt = Date()
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
            .filter(\._$verifiedAt == nil)
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
            reportId: report.requireID()
        )
    }
}
