//
//  UserApiController.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import Fluent

extension User.Account.List: Content {}
extension User.Account.Detail: Content {}

extension UserApiController: ApiController {
    
    typealias ApiModel = User.Account
    typealias DatabaseModel = UserAccountModel
    
    private func onlyForSelfOrModerator(_ req: Request, _ model: UserAccountModel) async throws {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require the model id to be the user id or the user to be an admin
        guard model.id == user.id || user.isModerator else {
            throw Abort(.forbidden)
        }
    }
    
    @AsyncValidatorBuilder
    func validators(optional: Bool) -> [AsyncValidator] {
        KeyedContentValidator<String>.required("name", optional: optional)
        KeyedContentValidator<String>.email("email", nil, optional)
    }
    
    func beforeList(_ req: Request, _ queryBuilder: QueryBuilder<UserAccountModel>) async throws -> QueryBuilder<UserAccountModel> {
        /// Require user to be signed in
        let authenticatedUser = try req.auth.require(AuthenticatedUser.self)
        /// find the user model belonging to the authenticated user
        guard let user = try await UserAccountModel.find(authenticatedUser.id, on: req.db) else {
            throw Abort(.unauthorized)
        }
        /// require  the user to be a moderator
        guard user.isModerator else {
            throw Abort(.forbidden)
        }
        
        return queryBuilder
    }
    
    func listOutput(_ req: Request, _ models: Page<UserAccountModel>) async throws -> Page<User.Account.List> {
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
        try model.setPassword(to: input.password, on: req)
        model.verified = false
        model.isModerator = false
    }
    
    func createResponse(_ req: Request, _ model: UserAccountModel) async throws -> Response {
        return try await User.Account.Detail.ownDetail(
            id: model.id!,
            name: model.name,
            email: model.email,
            school: model.school,
            verified: model.verified,
            isModerator: model.isModerator
        ).encodeResponse(status: .created, for: req)
    }
    
    func beforeUpdate(_ req: Request, _ model: UserAccountModel) async throws {
        try await onlyForSelfOrModerator(req, model)
    }
    
    /// Only use this when all fields are updated
    func updateInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Update) async throws {
        let previousEmail = model.email
        model.name = input.name
        model.email = input.email
        model.school = input.school
        if previousEmail != model.email {
            model.verified = false
            try await createVerification(req, model)
            try await model.$verificationToken.load(on: req.db)
            let userUpdateAccountMail = try UserUpdateEmailAccountTemplate(user: model, oldEmail: previousEmail)
            try await userUpdateAccountMail.send(on: req)
        }
    }
    
    func beforePatch(_ req: Request, _ model: UserAccountModel) async throws {
        try await onlyForSelfOrModerator(req, model)
    }
    
    func patchInput(_ req: Request, _ model: UserAccountModel, _ input: User.Account.Patch) async throws {
        let previousEmail = model.email
        model.name = input.name ?? model.name
        model.email = input.email ?? model.email
        if let setSchool = input.setSchool, setSchool {
            model.school = input.school
        }
        if previousEmail != model.email {
            model.verified = false
            try await createVerification(req, model)
            try await model.$verificationToken.load(on: req.db)
            let userUpdateAccountMail = try UserUpdateEmailAccountTemplate(user: model, oldEmail: previousEmail)
            try await userUpdateAccountMail.send(on: req)
        }
    }
    
    func beforeDelete(_ req: Request, _ model: UserAccountModel) async throws {
        try await onlyForSelfOrModerator(req, model)
    }
    
    func setupRoutes(_ routes: RoutesBuilder) {
        let protectedRoutes = routes.grouped(AuthenticatedUser.guardMiddleware())
        setupListRoutes(protectedRoutes)
        setupDetailRoutes(routes)
        setupCreateRoutes(routes)
        setupUpdateRoutes(protectedRoutes)
        setupPatchRoutes(protectedRoutes)
        setupDeleteRoutes(protectedRoutes)
    }
}
