//
//  File.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Foundation

public extension User {

    enum Token: ApiModelInterface {
        public typealias Module = User
    }
}

public extension User.Token {
    
    struct Detail: Codable {
        public let id: UUID
        public let value: String
        public let user: User.Account.Detail
        
        public init(id: UUID, value: String, user: User.Account.Detail) {
            self.id = id
            self.value = value
            self.user = user
        }
    }
}
