//
//  File.swift
//  
//
//  Created by niklhut on 07.02.22.
//

import Foundation

public extension User {
    enum Role: String, Codable, ApiModelInterface {
        public typealias Module = User
        
        case user, moderator, admin, superAdmin
        
        func authorizationLevel() -> Int {
            switch self {
            case .user: return 0
            case .moderator: return 1
            case .admin: return 2
            case .superAdmin: return 3
            }
        }
    }
}

extension User.Role: Comparable {
    public static func < (lhs: User.Role, rhs: User.Role) -> Bool {
        lhs.authorizationLevel() < rhs.authorizationLevel()
    }
}
