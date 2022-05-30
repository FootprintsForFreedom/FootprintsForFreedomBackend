//
//  DetailModel.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol DetailModel: DatabaseModelInterface {
    associatedtype Repository: RepositoryModel
    
    var verified: Bool { get set }
    var _$verified: FieldProperty<Self, Bool> { get }
    
    var language: LanguageModel { get }
    var _$language: ParentProperty<Self, LanguageModel> { get }
    
    var repository: Repository { get }
    var _$repository: ParentProperty<Self, Repository> { get }
    
    var user: UserAccountModel? { get }
    var _$user: OptionalParentProperty<Self, UserAccountModel> { get }
    
    var createdAt: Date? { get }
    var updatedAt: Date? { get }
    var deletedAt: Date? { get }
    
    var _$updatedAt: TimestampProperty<Self, DefaultTimestampFormat> { get }
}

extension DetailModel {
    func user() throws -> User.Account.Detail? {
        if let user = user {
            return try .publicDetail(id: user.requireID(), name: user.name, school: user.school)
        }
        return nil
    }
}
