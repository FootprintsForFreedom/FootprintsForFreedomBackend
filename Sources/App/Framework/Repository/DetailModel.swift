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
/// The detail model contains timestamps, a status, the repository it belongs to and the user who created it.
protocol DetailModel: DatabaseModelInterface, Timestamped {
    /// The type of the repository model to which the detail belongs.
    associatedtype Repository: RepositoryModel
    
    /// The detail's status.
    var status: Status { get set }
    /// The detail's status.
    var _$status: EnumProperty<Self, Status> { get }
    
    /// The detail's repository.
    var repository: Repository { get }
    /// The detail's repository.
    var _$repository: ParentProperty<Self, Repository> { get }
    
    /// The key path for the detail model on the repository.
    var ownKeyPathOnRepository: KeyPath<Repository, ChildrenProperty<Repository, Self>> { get }
    
    /// The user who created the detail model.
    ///
    /// If the user was deleted after creating the detail model, the user is set to nil.
    var user: UserAccountModel? { get }
    /// The user who created the detail model.
    ///
    /// If the user was deleted after creating the detail model, the user is set to nil.
    var _$user: OptionalParentProperty<Self, UserAccountModel> { get }
}

extension DetailModel {
    /// Gets a detail model for a repository.
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - repositoryId: The id for the repository for which to get a detail.
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    static func firstFor(
        _ repositoryId: UUID,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> Self? {
        let verifiedDetail = try await Self
            .query(on: db)
            .filter(\._$repository.$id == repositoryId)
            .filter(\._$status ~~ [.verified, .deleteRequested])
            .sort(\._$updatedAt, sortDirection)
            .first()
        
        if let verifiedDetail = verifiedDetail {
            return verifiedDetail
        } else if needsToBeVerified == false {
            return try await Self
                .query(on: db)
                .filter(\._$repository.$id == repositoryId)
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
    ///   - repository: The repository for which to get a detail
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func firstFor(
        _ repository: Repository,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> Self? {
        try await repository[keyPath: ownKeyPathOnRepository].firstFor(needsToBeVerified: needsToBeVerified, on: db, sort: sortDirection)
    }
}

extension ChildrenProperty where From: RepositoryModel, To: DetailModel {
    /// Gets the first detail model matching the requirements..
    ///
    /// This function always returns a verified detail when it exists, if `needsToBeVerified` is false it returns an unverified model when no verified detail exists, if false it returns nil.
    /// - Parameters:
    ///   - needsToBeVerified: Wether or not the detail needs to be verified.
    ///   - db: The database on which to load the detail model.
    ///   - sortDirection: The direction in which the detail's `updatedAt` timestamp should be sorted.
    /// - Returns: The first detail model matching the requirements or nil.
    func firstFor(
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction = .descending // newest first by default
    ) async throws -> To? {
        let verifiedDetail = try await projectedValue
            .query(on: db)
            .sort(\._$updatedAt, sortDirection)
            .filter(\._$status ~~ [.verified, .deleteRequested])
            .first()
        
        if let verifiedDetail = verifiedDetail {
            return verifiedDetail
        } else if needsToBeVerified == false {
            return try await projectedValue
                .query(on: db)
                .sort(\._$updatedAt, sortDirection)
                .first()
        } else {
            return nil
        }
    }
}
