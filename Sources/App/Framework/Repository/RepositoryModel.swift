//
//  RepositoryModel.swift
//  
//
//  Created by niklhut on 26.05.22.
//

import Vapor
import Fluent

protocol RepositoryModel: DatabaseModelInterface, Timestamped {
    associatedtype Detail: DetailModel
    associatedtype Report: ReportModel
    
    var details: [Detail] { get }
    var _$details: ChildrenProperty<Self, Detail> { get }
    
    var reports: [Report] { get }
    var _$reports: ChildrenProperty<Self, Report> { get }
    
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
    
    func containsVerifiedDetail(_ db: Database) async throws -> Bool {
        let verifiedDetailsCount = try await _$details
            .query(on: db)
            .filter(\._$status ~~ [.verified, .deleteRequested])
            .count()
        
        return verifiedDetailsCount > 0
    }
    
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
    
    func availableLanguageCodes(_ db: Database) async throws -> [String] {
        return try await availableLanguages(db).map(\.languageCode)
    }
}
