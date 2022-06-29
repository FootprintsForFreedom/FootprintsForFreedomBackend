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
protocol ReportModel: DatabaseModelInterface, Timestamped, Titled, Slugable {
    /// The type of the repository model to which the report belongs.
    associatedtype Repository: RepositoryModel
    
    /// The report's status.
    var status: Status { get set }
    /// The report's status.
    var _$status: EnumProperty<Self, Status> { get }
    
    /// The reason for which the repository was reported.
    var reason: String { get set }
    /// The reason for which the repository was reported.
    var _$reason: FieldProperty<Self, String> { get }
    
    /// The detail model which was visible to the user while reporting.
    var visibleDetail: Repository.Detail? { get set }
    /// The detail model which was visible to the user while reporting.
    var _$visibleDetail: OptionalParentProperty<Self, Repository.Detail> { get }
    
    /// The report's repository.
    var repository: Repository { get }
    /// The report's repository.
    var _$repository: ParentProperty<Self, Repository> { get }
    
    /// The user who created the report model.
    ///
    /// If the user was deleted after creating the report model, the user is set to nil.
    var user: UserAccountModel? { get }
    
    /// The user who created the report model.
    ///
    /// If the user was deleted after creating the report model, the user is set to nil.
    var _$user: OptionalParentProperty<Self, UserAccountModel> { get }
}
