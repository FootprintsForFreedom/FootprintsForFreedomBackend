//
//  RedirectDetail.swift
//  
//
//  Created by niklhut on 16.01.23.
//

import Foundation

public extension Redirect {
    /// Contains the redirect detail data transfer objects.
    enum Detail: ApiModelInterface {
        public typealias Module = AppApi.Redirect
    }
}

public extension Redirect.Detail {
    /// Used to detail redirect objects.
    struct Detail: Codable {
        /// Id uniquely identifying the redirect.
        public let id: UUID
        /// The source path from which to redirect from.
        public let source: String
        /// The destination path to which to redirect.
        public let destination: String
        
        /// Creates a redirect detail object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the redirect.
        ///   - source: The source path from which to redirect from.
        ///   - destination: The destination path to which to redirect.
        public init(id: UUID, source: String, destination: String) {
            self.id = id
            self.source = source
            self.destination = destination
        }
    }
    
    /// Used to list redirect objects.
    typealias List = Detail
    
    /// Used to create redirect objects.
    struct Create: Codable {
        /// The source path from which to redirect from.
        public let source: String
        /// The destination path to which to redirect.
        public let destination: String
        
        /// Creates a redirect detail object.
        /// - Parameters:
        ///   - source: The source path from which to redirect from.
        ///   - destination: The destination path to which to redirect.
        public init(source: String, destination: String) {
            self.source = source
            self.destination = destination
        }
    }
    
    // Used to update redirect objects.
    typealias Update = Create
    
    /// Used to create redirect objects.
    struct Patch: Codable {
        /// The source path from which to redirect from.
        public let source: String?
        /// The destination path to which to redirect.
        public let destination: String?
        
        /// Creates a redirect detail object.
        /// - Parameters:
        ///   - source: The source path from which to redirect from.
        ///   - destination: The destination path to which to redirect.
        public init(source: String?, destination: String?) {
            self.source = source
            self.destination = destination
        }
    }
}
