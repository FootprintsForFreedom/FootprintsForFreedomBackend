//
//  UserAcount.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Foundation

public extension User {

    enum Account: ApiModelInterface {
        public typealias Module = User
    }
}

public extension User.Account {
    
    struct Login: Codable {
        public let email: String
        public let password: String
        
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
    }
    
    struct Verification: Codable {
        public let token: String
        
        public init(token: String) {
            self.token = token
        }
    }
    
    struct ResetPasswordRequest: Codable {
        public let email: String
        
        public init(email: String) {
            self.email = email
        }
    }
    
    struct ResetPassword: Codable {
        public let token: String
        public let newPassword: String
        
        public init(token: String, newPassword: String) {
            self.token = token
            self.newPassword = newPassword
        }
    }
    
    struct ChangePassword: Codable  {
        public let currentPassword: String
        public let newPassword: String
        
        public init(currentPassword: String, newPassword: String) {
            self.currentPassword = currentPassword
            self.newPassword = newPassword
        }
    }
    
    struct ChangeRole: Codable {
        public let newRole: User.Role
        
        public init(newRole: User.Role) {
            self.newRole = newRole
        }
    }
    
    /// Only for admins
    struct List: Codable {
        public let id: UUID
        public let name: String
        public let school: String?
        public let verified: Bool
        public let role: User.Role
        
        public init(id: UUID, name: String, school: String?, verified: Bool, role: User.Role) {
            self.id = id
            self.name = name
            self.school = school
            self.verified = verified
            self.role = role
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let name: String
        public let email: String?
        public let school: String?
        public let verified: Bool?
        public let role: User.Role?
        
        public static func publicDetail(id: UUID, name: String, school: String?) -> Self {
            return .init(
                id: id,
                name: name,
                school: school
            )
        }
        
        public static func ownDetail(id: UUID, name: String, email: String, school: String?, verified: Bool, role: User.Role) -> Self {
            return .init(
                id: id,
                name: name,
                email: email,
                school: school,
                verified: verified,
                role: role
            )
        }
        
        public static func adminDetail(id: UUID, name: String, school: String?, verified: Bool, role: User.Role) -> Self {
            return .init(
                id: id,
                name: name,
                school: school,
                verified: verified,
                role: role
            )
        }
        
        private init(id: UUID, name: String, school: String?) {
            self.id = id
            self.name = name
            self.school = school
            self.email = nil
            self.verified = nil
            self.role = nil
        }
        
        private init(id: UUID, name: String, school: String?, verified: Bool, role: User.Role) {
            self.id = id
            self.name = name
            self.school = school
            self.verified = verified
            self.role = role
            self.email = nil
        }
        
        private init(id: UUID, name: String, email: String, school: String?, verified: Bool, role: User.Role) {
            self.id = id
            self.name = name
            self.email = email
            self.school = school
            self.verified = verified
            self.role = role
        }
    }
    
    struct Create: Codable {
        public let name: String
        public let email: String
        public let school: String?
        public let password: String
        
        public init(name: String, email: String, school: String?, password: String) {
            self.name = name
            self.email = email
            self.school = school
            self.password = password
        }
    }
    
    struct Update: Codable {
        public let name: String
        public let email: String
        public let school: String?
        
        public init(name: String, email: String, school: String?) {
            self.name = name
            self.email = email
            self.school = school
        }
    }
    
    struct Patch: Codable {
        public let name: String?
        public let email: String?
        public let setSchool: Bool?
        public let school: String?
        
        public init(name: String?, email: String?, setSchool: Bool, school: String?) {
            self.name = name
            self.email = email
            self.setSchool = setSchool
            self.school = school
        }
    }
}
