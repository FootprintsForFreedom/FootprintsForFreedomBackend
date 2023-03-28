//
//  ReportModel.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

/// A repository report model.
///
/// The report model also contains a title, timestamps and a slug.
protocol ReportModel: DetailModel, Titled, Slugable {
    /// The reason for which the repository was reported.
    var reason: String { get set }
    /// The reason for which the repository was reported.
    var _$reason: FieldProperty<Self, String> { get }
    
    /// The detail model which was visible to the user while reporting.
    var visibleDetail: Repository.Detail? { get set }
    /// The detail model which was visible to the user while reporting.
    var _$visibleDetail: OptionalParentProperty<Self, Repository.Detail> { get }
}

extension ReportModel where Repository: Reportable {
    var ownKeyPathOnRepository: KeyPath<Repository, ChildrenProperty<Repository, Repository.Report>> { \._$reports }
}
