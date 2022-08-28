//
//  Slugable.swift
//  
//
//  Created by niklhut on 08.06.22.
//

import Vapor
import Fluent

/// Represents an object that has an unique slug identifier.
protocol Slugable where Self: Fluent.Model {
    /// The model's slug.
    var slug: String { get set }
    /// The model's slug.
    var _$slug: FieldProperty<Self, String> { get }
}

extension Slugable {
    /// Generates a slug for the model and returns it.
    /// - Parameters:
    ///   - title: The title from which to create the slug.
    ///   - date: The date to use for further detail in the slug.
    ///   - accuracy: The desired date's accuracy.
    ///   - db: The database on which to check if the slug already exists.
    /// - Returns: The generated slug for the model.
    func generateSlug(for title: String, _ date: Date? = nil, with accuracy: Date.Accuracy = .none, on db: Database) async throws -> String {
        let newTitle = accuracy == .none ? title : title.appending(" ").appending((date ?? Date()).toString(with: accuracy))
        let slug = newTitle.slugify()
        let numberOfDetailsWithSlug = try await Self
            .query(on: db)
            .filter(\._$slug == slug)
            .count()
        if numberOfDetailsWithSlug == 0 {
            return slug
        } else if accuracy == .exact {
            return try await generateSlug(for: title, nil, with: accuracy, on: db)
        } else {
            let newAccuracy = accuracy.increased()
            return try await generateSlug(for: title, date, with: newAccuracy, on: db)
        }
    }
}

extension Slugable where Self: Titled, Self: Timestamped {
    /// Generates a slug for a model with a title and timestamps and returns it.
    /// - Parameters:
    ///   - accuracy: The desired date's accuracy.
    ///   - db: The database on which to check if the slug already exists.
    /// - Returns: The generated slug for the model.
    func generateSlug(with accuracy: Date.Accuracy = .none, on db: Database) async throws -> String {
        try await generateSlug(for: self.title, self.createdAt, with: accuracy, on: db)
    }
}
