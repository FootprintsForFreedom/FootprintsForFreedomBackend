//
//  UserAccount.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Foundation

public extension User {
    /// Contains the user account  data transfer objects.
    enum Account: ApiModelInterface {
        public typealias Module = User
    }
}

public extension User.Account {
    /// Used to login.
    struct Login: Codable {
        /// The user's email address.
        public let email: String
        /// The password set by the user for his account.
        public let password: String
        
        /// Creates a user login object.
        /// - Parameters:
        ///   - email: The user's email address.
        ///   - password: The password set by the user for his account.
        public init(email: String, password: String) {
            self.email = email
            self.password = password
        }
    }
    
    /// Used to verify a user's email address.
    struct Verification: Codable {
        /// The verification token for the user email.
        public let token: String
        
        /// Creates a user email verification object.
        /// - Parameter token: The verification token for the user email.
        public init(token: String) {
            self.token = token
        }
    }
    
    /// Used to request a password reset.
    struct ResetPasswordRequest: Codable {
        /// The email address for the user who forgot his password.
        public let email: String
        
        /// Creates a user reset password request object.
        /// - Parameter email: The email address for the user who forgot his password.
        public init(email: String) {
            self.email = email
        }
    }
    
    /// Used to reset a user password.
    struct ResetPassword: Codable {
        /// The token for the user to reset his password.
        public let token: String
        /// The new password set by the user for his account.
        public let newPassword: String
        
        /// Creates a user reset password object.
        /// - Parameters:
        ///   - token: The token for the user to reset his password.
        ///   - newPassword: The new password set by the user for his account.
        public init(token: String, newPassword: String) {
            self.token = token
            self.newPassword = newPassword
        }
    }
    
    /// Used to change a user password.
    struct ChangePassword: Codable  {
        /// The current password set by the user for his account.
        public let currentPassword: String
        /// The new password set by the user for his account.
        public let newPassword: String
        
        /// Creates a user change password object.
        /// - Parameters:
        ///   - currentPassword: The current password set by the user for his account.
        ///   - newPassword: The new password set by the user for his account.
        public init(currentPassword: String, newPassword: String) {
            self.currentPassword = currentPassword
            self.newPassword = newPassword
        }
    }
    
    /// Used to change a user's role.
    struct ChangeRole: Codable {
        /// The new role for the user. The new role cannot be higher than the role of the user initiating the role change.
        public let newRole: User.Role
        
        /// Creates a user change role object.
        /// - Parameter newRole: The new role for the user. The new role cannot be higher than the role of the user initiating the role change.
        public init(newRole: User.Role) {
            self.newRole = newRole
        }
    }
    
    /// Used to list users.
    struct List: Codable {
        /// Id uniquely identifying the user.
        public let id: UUID
        /// The user name.
        public let name: String
        /// The password set by the user for his account.
        public let school: String?
        /// Wether or not the user's email has been verified.
        public let verified: Bool
        /// The user's role.
        public let role: User.Role
        
        /// Creates a user list object.
        ///
        /// Since the list object contains sensitive details it should only be returned for moderators.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - school: The password set by the user for his account.
        ///   - verified: Wether or not the user's email has been verified.
        ///   - role: The user's role.
        public init(id: UUID, name: String, school: String?, verified: Bool, role: User.Role) {
            self.id = id
            self.name = name
            self.school = school
            self.verified = verified
            self.role = role
        }
    }
    
    /// Used to detail users.
    struct Detail: Codable {
        /// Id uniquely identifying the user.
        public let id: UUID
        /// The user name.
        public let name: String
        /// The user's email address.
        public let email: String?
        /// The school of the user.
        public let school: String?
        /// Wether or not the user's email has been verified.
        public let verified: Bool?
        /// The user's role.
        public let role: User.Role?
        
        /// Creates a user detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - school: The school of the user.
        /// - Returns: A user detail object.
        public static func publicDetail(id: UUID, name: String, school: String?) -> Self {
            return .init(
                id: id,
                name: name,
                school: school
            )
        }
        
        /// Creates a detail object for the user himself.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - email: The user's email address.
        ///   - school: The school of the user.
        ///   - verified: Wether or not the user's email has been verified.
        ///   - role: The user's role.
        /// - Returns: A user detail object.
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
        
        /// Creates a detail object for an admin.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - school: The school of the user.
        ///   - verified: Wether or not the user's email has been verified.
        ///   - role: The user's role.
        /// - Returns: A user detail object.
        public static func adminDetail(id: UUID, name: String, school: String?, verified: Bool, role: User.Role) -> Self {
            return .init(
                id: id,
                name: name,
                school: school,
                verified: verified,
                role: role
            )
        }
        
        /// Creates a user detail object for everyone.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - school: The school of the user.
        private init(id: UUID, name: String, school: String?) {
            self.id = id
            self.name = name
            self.school = school
            self.email = nil
            self.verified = nil
            self.role = nil
        }
        
        /// Creates a detail object for an admin.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - school: The school of the user.
        ///   - verified: Wether or not the user's email has been verified.
        ///   - role: The user's role.
        private init(id: UUID, name: String, school: String?, verified: Bool, role: User.Role) {
            self.id = id
            self.name = name
            self.school = school
            self.verified = verified
            self.role = role
            self.email = nil
        }
        
        /// Creates a detail object for the user himself.
        /// - Parameters:
        ///   - id: Id uniquely identifying the user.
        ///   - name: The user name.
        ///   - email: The user's email address.
        ///   - school: The school of the user.
        ///   - verified: Wether or not the user's email has been verified.
        ///   - role: The user's role.
        private init(id: UUID, name: String, email: String, school: String?, verified: Bool, role: User.Role) {
            self.id = id
            self.name = name
            self.email = email
            self.school = school
            self.verified = verified
            self.role = role
        }
    }
    
    /// Used to create users.
    struct Create: Codable {
        /// The user name.
        public let name: String
        /// The user's email address.
        public let email: String
        /// The school of the user. If no value is set the user's school will be set to no value.
        public let school: String?
        /// The password set by the user for his account.
        public let password: String
        
        /// Creates a user create object.
        /// - Parameters:
        ///   - name: The user name.
        ///   - email: The user's email address.
        ///   - school: The school of the user.  If no value is set the user's school will be set to no value.
        ///   - password: The password set by the user for his account.
        public init(name: String, email: String, school: String?, password: String) {
            self.name = name
            self.email = email
            self.school = school
            self.password = password
        }
    }
    
    /// Used to update users.
    struct Update: Codable {
        /// The user name.
        public let name: String
        /// The user's email address.
        public let email: String
        /// The school of the user. If no value is set the user's school will be set to no value.
        public let school: String?
        
        /// Creates a user update object.
        /// - Parameters:
        ///   - name: The user name.
        ///   - email: The user's email address.
        ///   - school: The school of the user. If no value is set the user's school will be set to no value.
        public init(name: String, email: String, school: String?) {
            self.name = name
            self.email = email
            self.school = school
        }
    }
    
    /// Used to patch users.
    struct Patch: Codable {
        /// The user name.
        public let name: String?
        /// The user's email address.
        public let email: String?
        /// Wether or not to set the school.
        ///
        /// A ``school`` value will only be considered if ``setSchool`` is set to true. If ``setSchool`` is true but no school value is set, the user's school will also be set to no value.
        public let setSchool: Bool?
        /// The school of the user.
        public let school: String?
        
        /// Creates a user patch object.
        /// - Parameters:
        ///   - name: The user name.
        ///   - email: The user's email address.
        ///   - setSchool: Wether or not to set the school. A ``school`` value will only be considered if ``setSchool`` is set to true. If ``setSchool`` is true but no school value is set, the user's school will also be set to no value.
        ///   - school: The school of the user.
        public init(name: String?, email: String?, setSchool: Bool, school: String?) {
            self.name = name
            self.email = email
            self.setSchool = setSchool
            self.school = school
        }
    }
}
