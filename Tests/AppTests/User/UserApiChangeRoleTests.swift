//
//  UserApiChangeRoleTests.swift
//  
//
//  Created by niklhut on 07.02.22.
//

@testable import App
import XCTVapor
import Fluent
import Spec

extension User.Account.ChangeRole: Content {}

final class UserApiChangeRoleTests: AppTestCase, UserTest {
    func testSuccessfulChangeUserRole() async throws {
        let allRoles = User.Role.allCases
        
        for userRole in allRoles {
            let user = try await createNewUser(role: userRole)
            let possibleRolesToChangeUserRole = allRoles.filter { $0 >= userRole && $0 >= .admin }
            
            for changingUserRole in possibleRolesToChangeUserRole {
                XCTAssertNotEqual(changingUserRole, .user)
                XCTAssertNotEqual(changingUserRole, .moderator)
                XCTAssertGreaterThanOrEqual(changingUserRole, userRole)
                
                let changingUserToken = try await getToken(for: changingUserRole)
                let possibleNewRoleForUser = allRoles.filter { $0 <= changingUserRole }
                
                for newRole in possibleNewRoleForUser {
                    XCTAssertLessThanOrEqual(newRole, changingUserRole)
                    
                    let changeRoleContent = User.Account.ChangeRole(newRole: newRole)
                    
                    try app
                        .describe("User should be able to update role of user to role as high or lower as his own role")
                        .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
                        .body(changeRoleContent)
                        .bearerToken(changingUserToken)
                        .expect(.ok)
                        .expect(.json)
                        .expect(User.Account.Detail.self) { content in
                            XCTAssertEqual(content.id, user.id)
                            XCTAssertEqual(content.name, user.name)
                            XCTAssertEqual(content.school, user.school)
                            if changingUserRole == .superAdmin {
                                XCTAssertEqual(content.email, user.email)
                            } else {
                                XCTAssertNil(content.email)
                            }
                            XCTAssertEqual(content.verified, user.verified)
                            XCTAssertEqual(content.role, changeRoleContent.newRole)
                        }
                        .test()
                }
            }
        }
    }
    
    func testChangeUserRoleToHigherRoleThanSelfFails() async throws {
        let allRoles = User.Role.allCases
        
        for userRole in allRoles {
            let user = try await createNewUser(role: userRole)
            let possibleRolesToChangeUserRole = allRoles.filter { $0 >= userRole && $0 != .user }
            
            for changingUserRole in possibleRolesToChangeUserRole {
                XCTAssertNotEqual(changingUserRole, .user)
                XCTAssertGreaterThanOrEqual(changingUserRole, userRole)
                
                let changingUserToken = try await getToken(for: changingUserRole)
                let rolesHigherThanChangingUser = allRoles.filter { $0 > changingUserRole }
                
                for newRole in rolesHigherThanChangingUser {
                    XCTAssertGreaterThanOrEqual(newRole, changingUserRole)
                    
                    let changeRoleContent = User.Account.ChangeRole(newRole: newRole)
                    
                    try app
                        .describe("User should not be able to update role of user to role higher than his own")
                        .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
                        .body(changeRoleContent)
                        .bearerToken(changingUserToken)
                        .expect(.forbidden)
                        .test()
                }
            }
        }
    }
    
    func testChangeRoleOfHigherUserFails() async throws {
        let allRoles = User.Role.allCases
        
        let possibleUserRoles = allRoles.filter { $0 != .user }
        for userRole in possibleUserRoles {
            let user = try await createNewUser(role: userRole)
            let rolesToNotBeAbleToChangeUserRole = allRoles.filter { $0 < userRole }
            
            for changingUserRole in rolesToNotBeAbleToChangeUserRole {
                XCTAssertLessThan(changingUserRole, userRole)
                
                let changingUserToken = try await getToken(for: changingUserRole)
                let rolesHigherThanChangingUser = allRoles.filter { $0 > changingUserRole }
                
                for newRole in rolesHigherThanChangingUser {
                    XCTAssertGreaterThanOrEqual(newRole, changingUserRole)
                    
                    let changeRoleContent = User.Account.ChangeRole(newRole: newRole)
                    
                    try app
                        .describe("User should not be able to update role of user who has a higher role than himself")
                        .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
                        .body(changeRoleContent)
                        .bearerToken(changingUserToken)
                        .expect(.forbidden)
                        .test()
                }
            }
        }
    }
    
    func testChangeUserRoleAsModeratorFails() async throws {
        let allRoles = User.Role.allCases
        
        for userRole in allRoles {
            let user = try await createNewUser(role: userRole)
            
            let changingUserToken = try await getToken(for: .moderator)
            let possibleNewRoleForUser = allRoles
            
            for newRole in possibleNewRoleForUser {
                let changeRoleContent = User.Account.ChangeRole(newRole: newRole)
                
                try app
                    .describe("Moderator should not be able to update role of other user")
                    .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
                    .body(changeRoleContent)
                    .bearerToken(changingUserToken)
                    .expect(.forbidden)
                    .test()
            }
        }
    }
    
    func testChangeOwnUserRoleFails() async throws {
        let allRoles = User.Role.allCases
        
        for userRole in allRoles {
            let user = try await createNewUser(role: userRole)
            let ownToken = try user.generateToken()
            try await ownToken.create(on: app.db)
            
            for newRole in allRoles {
                let changeRoleContent = User.Account.ChangeRole(newRole: newRole)
                
                try app
                    .describe("User should not be able to update his own role")
                    .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
                    .body(changeRoleContent)
                    .bearerToken(ownToken.value)
                    .expect(.forbidden)
                    .test()
            }
        }
    }
    
    func testChangeUserRoleWithoutTokenFails() async throws {
        let allRoles = User.Role.allCases
        
        for userRole in allRoles {
            let user = try await createNewUser(role: userRole)
            for newRole in allRoles {
                let changeRoleContent = User.Account.ChangeRole(newRole: newRole)
                
                try app
                    .describe("User should not be able to update role of user without sending token")
                    .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
                    .body(changeRoleContent)
                    .expect(.unauthorized)
                    .test()
            }
        }
    }
    
    func testChangeUserRoleWithWrongPayloadFails() async throws {
        let user = try await createNewUser()
        let changingUserToken = try await getToken(for: .superAdmin)
        
        try app
            .describe("Changing user role with wrong payload fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
            .body(["wrong input": "Test Category"])
            .bearerToken(changingUserToken)
            .expect(.badRequest)
            .test()
        
        try app
            .describe("Changing user role with wrong payload fails")
            .put(usersPath.appending(user.requireID().uuidString.appending("/changeRole")))
            .body(["newRole": "superDuperAdmin"])
            .bearerToken(changingUserToken)
            .expect(.internalServerError)
            .test()
    }
    
}
