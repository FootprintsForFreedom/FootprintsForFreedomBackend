//
//  RepositoryModel.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

/// A repository modle.
///
/// The repository model contains timestamps.
protocol RepositoryModel: DatabaseModelInterface, Timestamped {
    /// The type of the detail models which belong to the repository.
    associatedtype Detail: TitledDetailModel
    
    /// The details belonging to the repository.
    var details: [Detail] { get }
    /// The details belonging to the repository.
    var _$details: ChildrenProperty<Self, Detail> { get }
    
    /// Deletes all dependencies of the repository model.
    /// - Parameter db: The database on which to delete the dependencies.
    func deleteDependencies(on db: Database) async throws
}

extension RepositoryModel {
    /// Checks wether there is a verified detail available for the repository.
    /// - Parameter db: The database on which to check if a verified detail for the repository is available.
    /// - Returns: A boolean value indicating wether or not a verified detail is available for the repository.
    func containsVerifiedDetail(_ db: Database) async throws -> Bool {
        let verifiedDetailsCount = try await _$details
            .query(on: db)
            .filter(\._$status ~~ [.verified, .deleteRequested])
            .count()
        
        return verifiedDetailsCount > 0
    }
    
    /// Fetches all available languages in which the repository has **verified** detail models.
    /// - Parameter db: The database on which to fetch the available languages.
    /// - Returns: An array of all available languages for the repository.
    func availableLanguages(_ db: Database) async throws -> [LanguageModel] {
        let languageIds = try await self._$details
            .query(on: db)
            .join(parent: \._$language)
            .filter(LanguageModel.self, \.$priority != nil)
            .filter(\._$status ~~ [.verified, .deleteRequested])
            .field(\._$language.$id)
            .unique()
            .all()
            .map(\._$language.id)
        
        return try await languageIds.concurrentCompactMap { languageId in
            return try await LanguageModel.find(languageId, on: db)
        }
    }
    
    /// Fetches all available language codes in which the repository has **verified** detail models.
    /// - Parameter db: The database on which to fetch the available languages.
    /// - Returns: An array of all available language codes for the repository.
    func availableLanguageCodes(_ db: Database) async throws -> [String] {
        return try await availableLanguages(db).map(\.languageCode)
    }
    
    func deleteDependencies(on db: Database) async throws {
        try await _$details
            .query(on: db)
            .delete()
    }
}

extension RepositoryModel where Self: Reportable {
    func deleteDependencies(on db: Database) async throws {
        try await _$details
            .query(on: db)
            .delete()
        
        try await _$reports
            .query(on: db)
            .delete()
    }
}
