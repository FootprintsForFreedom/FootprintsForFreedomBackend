//
//  UserRoleTests.swift
//  
//
//  Created by niklhut on 07.02.22.
//

@testable import AppApi
import XCTest

final class UserRoleTests: XCTestCase {
    func testRoleHierachy() {
        XCTAssertGreaterThan(User.Role.moderator, User.Role.user)
        XCTAssertGreaterThan(User.Role.admin, User.Role.moderator)
        XCTAssertGreaterThan(User.Role.superAdmin, User.Role.admin)
    }
}
