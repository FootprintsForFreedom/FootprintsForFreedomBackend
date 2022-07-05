//
//  UserRole.swift
//  
//
//  Created by niklhut on 07.02.22.
//

import Foundation

public extension User {
    ///  Used to assign different roles to users.
    enum Role: String, Codable, CaseIterable, ApiModelInterface {
        public typealias Module = User
        
        /// A user can perform edits to content but his edits woh't be public.
        case user
        /// A moderator has the additional ability to verify user content so it is visible to the public.
        case moderator
        /// An admin has the additional ability to manage the users.
        case admin
        /// A superAdmin has some additional abilities.
        case superAdmin
        
        /// Determines the authorization level for a user.
        /// - Returns: The user's authorization level.
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
