//
//  Timestamped+SetDateFurtherThan.swift
//  
//
//  Created by niklhut on 28.08.22.

@testable import App
import Vapor
import Fluent

extension Timestamped {
    /// Sets a timestamp at the given path further back than the specified time in days.
    /// - Parameters:
    ///   - path: The path of the timestamp to edit.
    ///   - timeInDays: The time in days to set the date back.
    ///   - db: The database on which to change the timestamp.
    func `set`(_ path: ReferenceWritableKeyPath<any Timestamped, Date?>, furtherBackThan timeInDays: Int?, on db: Database) async throws {
        guard let timeInDays else {
            return
        }
        let dayInSeconds = 60 * 60 * 24
        self[keyPath: path] = Date().addingTimeInterval(TimeInterval(-1 * dayInSeconds * timeInDays))
        try await self.update(on: db)
    }
}
