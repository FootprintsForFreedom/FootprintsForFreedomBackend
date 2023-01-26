//
//  StaticContentMigrations.swift
//  
//
//  Created by niklhut on 09.06.22.
//

import Vapor
import Fluent
import AppApi

enum StaticContentMigrations {
    struct v1: AsyncMigration {
        func prepare(on db: Database) async throws {
            let _ = try await db.enum(StaticContent.Snippet.pathKey)
                .case(StaticContent.Snippet.username.rawValue)
                .case(StaticContent.Snippet.appName.rawValue)
                .case(StaticContent.Snippet.verificationLink.rawValue)
                .create()
            
            try await db.schema(StaticContentRepositoryModel.schema)
                .id()
            
                .field(StaticContentRepositoryModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: StaticContentRepositoryModel.FieldKeys.v1.slug)
            
                .field(StaticContentRepositoryModel.FieldKeys.v1.requiredSnippets, .sql(raw: "text[]"), .required)
            
                .field(StaticContentRepositoryModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(StaticContentRepositoryModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(StaticContentRepositoryModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
            
            try await db.schema(StaticContentDetailModel.schema)
                .id()
            
                .field(StaticContentDetailModel.FieldKeys.v1.moderationTitle, .string , .required)
                .field(StaticContentDetailModel.FieldKeys.v1.slug, .string, .required)
                .unique(on: StaticContentDetailModel.FieldKeys.v1.slug)
                .field(StaticContentDetailModel.FieldKeys.v1.title, .string , .required)
                .field(StaticContentDetailModel.FieldKeys.v1.text, .string, .required)
            
                .field(StaticContentDetailModel.FieldKeys.v1.languageId, .uuid, .required)
                .foreignKey(StaticContentDetailModel.FieldKeys.v1.languageId, references: LanguageModel.schema, .id)
            
                .field(StaticContentDetailModel.FieldKeys.v1.repositoryId, .uuid, .required)
                .foreignKey(StaticContentDetailModel.FieldKeys.v1.repositoryId, references: StaticContentRepositoryModel.schema, .id, onDelete: .cascade)
            
                .field(StaticContentDetailModel.FieldKeys.v1.userId, .uuid)
                .foreignKey(StaticContentDetailModel.FieldKeys.v1.userId, references: UserAccountModel.schema, .id, onDelete: .setNull)
            
                .field(StaticContentDetailModel.FieldKeys.v1.verifiedAt, .datetime)
                .field(StaticContentDetailModel.FieldKeys.v1.createdAt, .datetime, .required)
                .field(StaticContentDetailModel.FieldKeys.v1.updatedAt, .datetime, .required)
                .field(StaticContentDetailModel.FieldKeys.v1.deletedAt, .datetime)
            
                .create()
        }
        
        func revert(on db: Database) async throws {
            try await db.schema(StaticContentDetailModel.schema).delete()
            try await db.schema(StaticContentRepositoryModel.schema).delete()
            try await db.enum(StaticContent.Snippet.pathKey).delete()
        }
    }
    
    struct seed: AsyncMigration {
        static let createAccountSlug = "create-account-mail"
        static let passwordResetSlug = "password-reset-mail"
        static let updateEmailSlug = "update-email-mail"
        static let verifyAccountSlug = "verify-account-mail"
        
        func prepare(on db: Database) async throws {
            // get the admin user
            guard
                let admin = try await UserAccountModel.query(on: db).filter(\.$email == "root@localhost.com").first(),
                let language = try await LanguageModel.query(on: db).filter(\.$languageCode == "de").first()
            else {
                return
            }
            
            // create account mail
            let createAccountMailRepository = StaticContentRepositoryModel(slug: Self.createAccountSlug, requiredSnippets: [.username, .appName, .verificationLink])
            try await createAccountMailRepository.create(on: db)
            let createAccountMailDetail = try StaticContentDetailModel(
                moderationTitle: "Neuer Account Email",
                title: "Dein neuer <app-name> Account",
                text: """
                    Hallo <username>,
                    
                    willkommen bei <app-name>.
                    
                    Du hast dich erfolgreich angemeldet. Bitte bestätige mit dem folgenden Link deine E-Mail-Adresse:
                    <verification-link>
                    
                    Sobald deine E-Mail-Adresse bestätigt ist, kannst du Orte erstellen und Medien hochladen.
                    
                    Wir wünschen dir viel Spaß und hoffen, dass du neue Einblicke erhalten kannst.
                    
                    Dein <app-name> Team
                    
                    Diese E-Mail wurde automatisch erstellt. Bitte antworte nicht an diese Adresse.
                    """,
                languageId: language.requireID(),
                repositoryId: createAccountMailRepository.requireID(),
                userId: admin.requireID()
            )
            try await createAccountMailDetail.create(on: db)
            
            // password reset mail
            let passwordResetMailRepository = StaticContentRepositoryModel(slug: Self.passwordResetSlug, requiredSnippets: [.username, .appName, .verificationLink])
            try await passwordResetMailRepository.create(on: db)
            let passwordResetMailDetail = try StaticContentDetailModel(
                moderationTitle: "Passwort Zurücksetzen Email",
                title: "Dein neues Passwort für <app-name>",
                text: """
                    Hallo <username>,
                    
                    du hast eine Anfrage gesendet, um dein Passwort zurückzusetzten. Mit dem folgenden Link kannst du dies tun:
                    <verification-link>
                    
                    Falls du die Anfrage nicht geändert hast kannst du diese E-Mail ignorieren.
                    
                    Dein <app-name> Team
                    
                    Diese E-Mail wurde automatisch erstellt. Bitte antworte nicht an diese Adresse.
                    """,
                languageId: language.requireID(),
                repositoryId: passwordResetMailRepository.requireID(),
                userId: admin.requireID()
            )
            try await passwordResetMailDetail.create(on: db)
            
            // update email mail
            let updateEmailMailRepository = StaticContentRepositoryModel(slug: Self.updateEmailSlug, requiredSnippets: [.username, .appName, .verificationLink])
            try await updateEmailMailRepository.create(on: db)
            let updateEmailMailDetail = try StaticContentDetailModel(
                moderationTitle: "Neue E-Mail-Adresse Email",
                title: "Neue E-Mail-Adresse für <app-name>",
                text: """
                    Hallo <username>,
                    
                    deine E-Mail-Adresse wurde soeben geändert. Bitte bestätige mit dem folgenden Link deine neue E-Mail-Adresse:
                    <verification-link>
                    
                    Sobald deine neue E-Mail-Adresse bestätigt ist, kannst du Orte erstellen und Medien hochladen.
                    
                    Falls du die E-Mail nicht geändert hast, überprüfe bitte deine Account-Einstellungen und ändere dein Passwort.
                    
                    Dein <app-name> Team
                    
                    Diese E-Mail wurde automatisch erstellt. Bitte antworte nicht an diese Adresse.
                    """,
                languageId: language.requireID(),
                repositoryId: updateEmailMailRepository.requireID(),
                userId: admin.requireID()
            )
            try await updateEmailMailDetail.create(on: db)
            
            // verify account mail
            let verifyAccountMailRepository = StaticContentRepositoryModel(slug: Self.verifyAccountSlug, requiredSnippets: [.username, .appName, .verificationLink])
            try await verifyAccountMailRepository.create(on: db)
            let verifyAccountMailDetail = try StaticContentDetailModel(
                moderationTitle: "Verifiziere Account Email",
                title: "Bitte verifiziere deinen <app-name> Account",
                text: """
                    Hallo <username>,
                    
                    Vielen Dank, dass du <app-name> verwendest. Bitte bestätige mit dem folgenden Link deine E-Mail-Adresse:
                    <verification-link>
                    
                    Sobald deine E-Mail-Adresse bestätigt ist, kannst du Orte erstellen und Medien hochladen.
                    
                    Wir wünschen dir viel Spaß und hoffen, dass du neue Einblicke erhalten kannst.
                    
                    Dein <app-name> Team
                    
                    Diese E-Mail wurde automatisch erstellt. Bitte antworte nicht an diese Adresse.
                    """,
                languageId: language.requireID(),
                repositoryId: verifyAccountMailRepository.requireID(),
                userId: admin.requireID()
            )
            try await verifyAccountMailDetail.create(on: db)
        }
        
        func revert(on database: Database) async throws { }
    }
}
