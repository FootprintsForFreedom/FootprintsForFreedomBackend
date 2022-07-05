//
//  UserToken.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Foundation

public extension User {
    /// Contains the user token data transfer objects.
    enum Token: ApiModelInterface {
        public typealias Module = User
    }
}

public extension User.Token {
    /// Used to detail tokens.
    struct Detail: Codable {
        /// Id uniquely identifying the token.
        public let id: UUID
        /// The access token which can be used to access other api endpoints.
        public let access_token: String
        /// The user to which the token belongs.
        public let user: User.Account.Detail
        
        /// Creates a token detail object.
        /// - Parameters:
        ///   - id: Id uniquely identifying the token.
        ///   - access_token: The access token which can be used to access other api endpoints.
        ///   - user: The user to which the token belongs.
        public init(id: UUID, access_token: String, user: User.Account.Detail) {
            self.id = id
            self.access_token = access_token
            self.user = user
        }
    }
}
