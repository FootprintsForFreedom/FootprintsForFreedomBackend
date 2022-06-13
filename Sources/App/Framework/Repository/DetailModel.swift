//
//  DetailModel.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol DetailModel: DatabaseModelInterface, Timestamped, Titled, Slugable {
    associatedtype Repository: RepositoryModel
    
    var _$slug: FieldProperty<Self, String> { get }
    
    var status: Status { get set }
    var _$status: EnumProperty<Self, Status> { get }
    
    var language: LanguageModel { get }
    var _$language: ParentProperty<Self, LanguageModel> { get }
    
    var repository: Repository { get }
    var _$repository: ParentProperty<Self, Repository> { get }
    
    var user: UserAccountModel? { get }
    var _$user: OptionalParentProperty<Self, UserAccountModel> { get }
}

extension DetailModel {
    func user() throws -> User.Account.Detail? {
        if let user = user {
            return try .publicDetail(id: user.requireID(), name: user.name, school: user.school)
        }
        return nil
    }
}
