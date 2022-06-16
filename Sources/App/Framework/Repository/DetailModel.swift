//
//  DetailModel.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// A repository detail model.
///
/// The detail model also contains a title, timestamp and slug.
protocol DetailModel: DatabaseModelInterface, Timestamped, Titled, Slugable {
    associatedtype Repository: RepositoryModel
    
    /// The detail's status.
    var status: Status { get set }
    /// The detail's status.
    var _$status: EnumProperty<Self, Status> { get }
    
    /// The detail's language.
    var language: LanguageModel { get }
    /// The detail's language.
    var _$language: ParentProperty<Self, LanguageModel> { get }
    
    /// The detail's repository.
    var repository: Repository { get }
    /// The detail's repository.
    var _$repository: ParentProperty<Self, Repository> { get }
    
    /// The user who created the detail model.
    ///
    /// If the user was deleted after creating the detail model, the user is set to nil.
    var user: UserAccountModel? { get }
    /// The user who created the detail model.
    ///
    /// If the user was deleted after creating the detail model, the user is set to nil.
    var _$user: OptionalParentProperty<Self, UserAccountModel> { get }
}
