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
    
    var title: String { get set }
    
    var slug: String { get set }
    var _$slug: FieldProperty<Self, String> { get }
    
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
    
    func generateSlug(with accuracy: Date.Accuracy = .none, on db: Database) async throws -> String {
        let title = accuracy == .none ? self.title : self.title.appending(" ").appending((createdAt ?? Date()).toString(with: accuracy))
        let slug = title.slugify()
        let numberOfDetailsWithSlug = try await Self
            .query(on: db)
            .filter(\._$slug == slug)
            .count()
        if numberOfDetailsWithSlug == 0 {
            return slug
        } else {
            let newAccuracy = accuracy.increased()
            return try await generateSlug(with: newAccuracy, on: db)
        }
    }
}
