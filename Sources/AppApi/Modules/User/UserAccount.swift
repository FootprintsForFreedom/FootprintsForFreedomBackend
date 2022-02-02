//
//  File.swift
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
    
    struct ChangePassword: Codable  {
        public let currentPassword: String
        public let newPassword: String
        
        public init(currentPassword: String, newPassword: String) {
            self.currentPassword = currentPassword
            self.newPassword = newPassword
        }
    }
    
    /// Only for admins
    struct List: Codable {
        public let id: UUID
        public let name: String
        public let school: String?
        public let isModerator: Bool
        
        public init(id: UUID, name: String, school: String?, isModerator: Bool) {
            self.id = id
            self.name = name
            self.school = school
            self.isModerator = isModerator
        }
    }
    
    struct Detail: Codable {
        public let id: UUID
        public let name: String
        public let email: String?
        public let school: String?
        public let verified: Bool?
        public let isModerator: Bool?
        
        public static func publicDetail(id: UUID, name: String, school: String?) -> Self {
            return .init(id: id, name: name, school: school)
        }
        
        public static func ownDetail(id: UUID, name: String, email: String, school: String?, verified: Bool, isModerator: Bool) -> Self {
            return .init(id: id, name: name, email: email, school: school, verified: verified, isModerator: isModerator)
        }
        
        public static func adminDetail(id: UUID, name: String, school: String?, verified: Bool, isModerator: Bool) -> Self {
            return .init(id: id, name: name, school: school, verified: verified, isModerator: isModerator)
        }
        
        private init(id: UUID, name: String, school: String?) {
            self.id = id
            self.name = name
            self.school = school
            self.email = nil
            self.verified = nil
            self.isModerator = nil
        }
        
        private init(id: UUID, name: String, school: String?, verified: Bool, isModerator: Bool) {
            self.id = id
            self.name = name
            self.school = school
            self.verified = verified
            self.isModerator = isModerator
            self.email = nil
        }
        
        private init(id: UUID, name: String, email: String, school: String?, verified: Bool, isModerator: Bool) {
            self.id = id
            self.name = name
            self.email = email
            self.school = school
            self.verified = verified
            self.isModerator = isModerator
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
        public let school: String??
        
        public init(name: String?, email: String?, school: String??) {
            self.name = name
            self.email = email
            self.school = school
        }
    }
}
