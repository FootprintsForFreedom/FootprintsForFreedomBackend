//
//  UserApiController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor

extension User.Token.Detail: Content {}

struct UserApiController {
    
    func signInApi(req: Request) async throws -> User.Token.Detail {
        guard let authenticatedUser = req.auth.get(AuthenticatedUser.self) else {
            throw Abort(.unauthorized)
        }
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.notFound)
        }
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789="
        let tokenValue = String((0..<64).map { _ in letters.randomElement()! })
        let token = UserTokenModel(value: tokenValue, userId: user.id!)
        try await token.create(on: req.db)
        let userDetail = User.Account.Detail.ownDetail(id: user.id!, name: user.name, email: user.email, school: user.school, verified: user.verified, isModerator: user.isModerator)
        return User.Token.Detail(id: token.id!, value: token.value, user: userDetail)
    }
}

extension User.Account.List: Content {}
extension User.Account.Detail: Content {}

extension UserApiController: ApiController {
    
    typealias ApiModel = User.Account
    typealias DatabaseModel = UserAccountModel
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("name", optional: optional)
        KeyedContentValidator<String>.required("email", optional: optional)
    }
    
    func listOutput(_ req: Request, _ models: [UserAccountModel]) async throws -> [User.Account.List] {
        models.map { model in
                .init(id: model.id!, name: model.name, school: model.school, verified: model.verified, isModerator: model.isModerator)
        }
    }
    
    func detailOutput(_ req: Request, _ model: UserAccountModel) async throws -> User.Account.Detail {
        if let authenticatedUser = req.auth.get(AuthenticatedUser.self), let user = try await DatabaseModel.find(authenticatedUser.id, on: req.db) {
            if user.id == model.id {
                return User.Account.Detail.ownDetail(
                    id: model.id!,
                    name: model.name,
                    email: model.email,
                    school: model.school,
                    verified: model.verified,
                    isModerator: model.isModerator
                )
            } else if user.isModerator {
                return User.Account.Detail.adminDetail(
                    id: model.id!,
                    name: model.name,
                    school: model.school,
                    verified: model.verified,
                    isModerator: model.isModerator
                )
            }
        }
        
        return User.Account.Detail.publicDetail(
            id: model.id!,
            name: model.name,
            school: model.school
        )
    }
    
    func createInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Create) async throws {
        model.name = input.name
        model.email = input.email
        model.school = input.school
        model.password = try Bcrypt.hash(input.password)
        model.verified = false
        model.isModerator = false
    }
    
    func updateInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Update) async throws {
        model.name = input.name
        model.email = input.email
        model.school = input.school
    }
    
    func patchInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Patch) async throws {
        model.name = input.name ?? model.name
        model.email = input.email ?? model.email
        model.school = input.school ?? model.school
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(protectedRoutes)
        setupDetailRoutes(routes)
        setupCreateRoutes(protectedRoutes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
    
}

extension UserApiController: ApiUpdatePasswordController {
    typealias UpdatePasswordObject = User.Account.ChangePassword
    
    @AsyncValidatorBuilder
    func updatePasswordValidators() -> [AsyncValidator] {
        KeyedContentValidator<String>.required("currentPassword")
        KeyedContentValidator<String>.required("newPassword")
    }
    
    /// Require user to be logged in
    func updatePasswordInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.ChangePassword) async throws {
        guard let user = req.auth.get(AuthenticatedUser.self) else {
            throw Abort(.unauthorized)
        }
        
        /// Assure the user itself changes the password
        guard model.id == user.id else {
            throw Abort(.forbidden)
        }
        
        /// Verify current password
        guard try Bcrypt.verify(input.currentPassword, created: model.password) else {
            throw Abort(.forbidden)
        }
        
        /// Update the password
        model.password = try Bcrypt.hash(input.newPassword)
    }
    
    func updatePasswordResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        try await detailOutput(req, model).encodeResponse(for: req)
    }
    
    func setupUpdatePasswordRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        let baseRoutes = getBaseRoutes(protectedRoutes)
        let existingModelRoutes = baseRoutes.grouped(ApiModel.pathIdComponent).grouped("updatePassword")
        existingModelRoutes.put(use: updatePasswordApi)
    }
}
