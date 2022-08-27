//
//  File.swift
//  
//
//  Created by niklhut on 27.08.22.
//

import Vapor
import Fluent

/// A repository detail model with a title, slug and language.
///
/// The titled detail model contains, additionally to the timestamps, a status, the repository it belongs to and the user who created it, a language, title and slug.
protocol TitledDetailModel: DetailModel, Titled, Slugable {
    /// The detail's language.
    var language: LanguageModel { get }
    /// The detail's language.
    var _$language: ParentProperty<Self, LanguageModel> { get }
}

extension TitledDetailModel {
    /// Gets a detail model for the repository.
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - repository: The repository for which to get a detail
    ///   - languageCode: The language code for the language in which the detail should be.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func firstFor(
        _ repository: Repository,
        _ languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> Self? {
        try await repository[keyPath: ownKeyPathForRepository].firstFor(languageCode, needsToBeVerified: needsToBeVerified, on: db, sort: sortDirection)
    }
}

extension ChildrenProperty where From: RepositoryModel, To: TitledDetailModel {
    /// Gets the first detail model matching the requirements..
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - languageCode: The language code for the language in which the detail should be.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func firstFor(
        _ languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> To? {
        let verifiedDetail = try await projectedValue
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
            return try await projectedValue
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
    
    /// Gets the first detail model matching the requirements..
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - languageCodesByPriority: All valid language codes for the languages in which the detail should be returned ordered by priority with the preferred language first.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func firstFor(
        _ languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> To? {
        for languageCode in languageCodesByPriority {
            if let detail = try await firstFor(
                languageCode,
                needsToBeVerified: needsToBeVerified,
                on: db,
                sort: sortDirection
            ) {
                return detail
            }
        }
        return nil
    }
}
