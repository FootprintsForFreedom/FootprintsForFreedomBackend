//
//  Page+Map.swift
//  
//
//  Created by niklhut on 20.02.22.
//

import AppApi
import FluentKit

extension FluentKit.Page {
    /// Transform the sequence into a page of new values using
    /// an async closure.
    ///
    /// The closure calls will be performed concurrently, but the call
    /// to this function won't return until all of the closure calls
    /// have completed. If any of the closure calls throw an error,
    /// then the first error will be rethrown once all closure calls have
    /// completed.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence.
    /// - throws: Rethrows any error thrown by the passed closure.
    func concurrentMap<U>(_ transform: @escaping (T) async throws -> (U)) async throws -> FluentKit.Page<U> {
        try await .init(
            items: self.items.concurrentMap(transform),
            metadata: self.metadata)
    }
    
    /// Returns an array containing the non-`nil` results of calling the given
    /// transformation with each element of this sequence.
    ///
    /// Use this method to receive a page of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// - Parameter transform: A closure that accepts an element of this
    ///   sequence as its argument and returns an optional value.
    /// - Returns: An array of the non-`nil` results of calling `transform`
    ///   with each element of the sequence.
    ///
    /// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
    ///   and *m* is the length of the result.
    func compactMap<U>(_ transform: (T) throws -> U?) rethrows -> FluentKit.Page<U> {
        .init(
            items: try self.items.compactMap(transform),
            metadata: self.metadata
        )
    }
    
    /// Transform the sequence into a page of new values using
    /// an async closure that returns optional values. Only the
    /// non-`nil` return values will be included in the new array.
    ///
    /// The closure calls will be performed concurrently, but the call
    /// to this function won't return until all of the closure calls
    /// have completed. If any of the closure calls throw an error,
    /// then the first error will be rethrown once all closure calls have
    /// completed.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence,
    ///   except for the values that were transformed into `nil`.
    /// - throws: Rethrows any error thrown by the passed closure.
    func concurrentCompactMap<U>(_ transform: @escaping (T) async throws -> U?) async throws -> FluentKit.Page<U> {
        try await .init(
            items: self.items.concurrentCompactMap(transform),
            metadata: self.metadata)
    }
}

extension AppApi.Page {
    /// Transform the sequence into a page of new values using
    /// an async closure.
    ///
    /// The closure calls will be performed concurrently, but the call
    /// to this function won't return until all of the closure calls
    /// have completed. If any of the closure calls throw an error,
    /// then the first error will be rethrown once all closure calls have
    /// completed.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence.
    /// - throws: Rethrows any error thrown by the passed closure.
    func concurrentMap<U>(_ transform: @escaping (T) async throws -> (U)) async throws -> AppApi.Page<U> {
        try await .init(
            items: self.items.concurrentMap(transform),
            metadata: self.metadata)
    }
    
    /// Returns an array containing the non-`nil` results of calling the given
    /// transformation with each element of this sequence.
    ///
    /// Use this method to receive a page of non-optional values when your
    /// transformation produces an optional value.
    ///
    /// - Parameter transform: A closure that accepts an element of this
    ///   sequence as its argument and returns an optional value.
    /// - Returns: An array of the non-`nil` results of calling `transform`
    ///   with each element of the sequence.
    ///
    /// - Complexity: O(*m* + *n*), where *n* is the length of this sequence
    ///   and *m* is the length of the result.
    func compactMap<U>(_ transform: (T) throws -> U?) rethrows -> AppApi.Page<U> {
        .init(
            items: try self.items.compactMap(transform),
            metadata: self.metadata
        )
    }
    
    /// Transform the sequence into a page of new values using
    /// an async closure that returns optional values. Only the
    /// non-`nil` return values will be included in the new array.
    ///
    /// The closure calls will be performed concurrently, but the call
    /// to this function won't return until all of the closure calls
    /// have completed. If any of the closure calls throw an error,
    /// then the first error will be rethrown once all closure calls have
    /// completed.
    ///
    /// - parameter transform: The transform to run on each element.
    /// - returns: The transformed values as an array. The order of
    ///   the transformed values will match the original sequence,
    ///   except for the values that were transformed into `nil`.
    /// - throws: Rethrows any error thrown by the passed closure.
    func concurrentCompactMap<U>(_ transform: @escaping (T) async throws -> U?) async throws -> AppApi.Page<U> {
        try await .init(
            items: self.items.concurrentCompactMap(transform),
            metadata: self.metadata)
    }
}
