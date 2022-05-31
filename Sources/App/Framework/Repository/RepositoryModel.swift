//
//  RepositoryModel.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryModel: DatabaseModelInterface {
    associatedtype Detail: DetailModel
    
    var details: [Detail] { get }
    var _$details: ChildrenProperty<Self, Detail> { get }
    
    var createdAt: Date? { get }
    var updatedAt: Date? { get }
    var deletedAt: Date? { get }
    
    func detail(
        for languageCode: String,
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction
    ) async throws -> Detail?
    
    func detail(
        for languageCodesByPriority: [String],
        needsToBeVerified: Bool,
        on db: Database,
        sort sortDirection: DatabaseQuery.Sort.Direction
    ) async throws -> Detail?
}

extension RepositoryModel {
    // always returns verified detail when it exists, if needsToBeVerified is false it returns an unverified model when no verified one exists, if false it return nil
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
            .filter(\._$verified == true)
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
}
