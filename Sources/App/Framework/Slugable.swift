//
//  Slugable.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

protocol Slugable: Fluent.Model {
    var slug: String { get set }
    var _$slug: FieldProperty<Self, String> { get }
}

extension Slugable {
    func generateSlug(for title: String, _ date: Date? = nil, with accuracy: Date.Accuracy = .none, on db: Database) async throws -> String {
        let newTitle = accuracy == .none ? title : title.appending(" ").appending((date ?? Date()).toString(with: accuracy))
        let slug = newTitle.slugify()
        let numberOfDetailsWithSlug = try await Self
            .query(on: db)
            .filter(\._$slug == slug)
            .count()
        if numberOfDetailsWithSlug == 0 {
            return slug
        } else {
            let newAccuracy = accuracy.increased()
            return try await generateSlug(for: title, date, with: newAccuracy, on: db)
        }
    }
}

extension Slugable where Self: Titled, Self: Timestamped {
    func generateSlug(with accuracy: Date.Accuracy = .none, on db: Database) async throws -> String {
        try await generateSlug(for: self.title, self.createdAt, with: accuracy, on: db)
    }
}
