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
    associatedtype Detail: DetailModel
    
    /// The details belonging to the repository.
    var details: [Detail] { get }
    /// The details belonging to the repository.
    var _$details: ChildrenProperty<Self, Detail> { get }
        
    /// Gets a detail model for the repository.
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - languageCode: The language code for the language in which the detail should be.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func detail(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction
    ) async throws -> Detail?
    
    /// Gets a detail model for the repository.
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - languageCodesByPriority: All valid language codes for the languages in which the detail should be returned ordered by priority with the preferred language first.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func detail(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction
    ) async throws -> Detail?
    
    /// Deletes all dependencies of the repository model.
    /// - Parameter db: The database on which to delete the dependencies.
    func deleteDependencies(on db: Database) async throws
}

extension RepositoryModel {
    
    /// Gets a detail model for the repository.
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - languageCode: The language code for the language in which the detail should be.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted. Sorted by the newest by default.
    /// - Returns: The first detail model matching the requirements or nil.
    func detail(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> Detail? {
        let verifiedDetail = try await self._$details
            .query(on: db)
            .join(parent: \._$language)
            .filter(LanguageModel.self, \.$languageCode == languageCode)
            .filter(LanguageModel.self, \.$priority != nil)
            .sort(\._$updatedAt, sortDirection)
            .filter(\._$status ~~ [.verified, .deleteRequested])
            .first()
        
        if let verifiedDetail = verifiedDetail {
            return verifiedDetail
        } else if needsToBeVerified == false {
            return try await self._$details
                .query(on: db)
                .join(parent: \._$language)
                .filter(LanguageModel.self, \.$languageCode == languageCode)
                .filter(LanguageModel.self, \.$priority != nil)
                .sort(\._$updatedAt, sortDirection)
                .first()
        } else {
            return nil
        }
    }
    
    /// Gets a detail model for the repository.
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - languageCodesByPriority: All valid language codes for the languages in which the detail should be returned ordered by priority with the preferred language first.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted. Sorted by the newest by default.
    /// - Returns: The first detail model matching the requirements or nil.
    func detail(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> Detail? {
        for languageCode in languageCodesByPriority {
            if let detail = try await detail(
                for: languageCode,
                needsToBeVerified: needsToBeVerified,
                on: db,
                sort: sortDirection
            ) {
                return detail
            }
        }
        return nil
    }
    
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
