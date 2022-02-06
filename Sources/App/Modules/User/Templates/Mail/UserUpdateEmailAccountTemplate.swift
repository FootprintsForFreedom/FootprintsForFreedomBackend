//
//  UserUpdateEmailAccountTemplate.swift
//  
//
//  Created by niklhut on 03.02.22.
//

import Vapor
import SMTPKitten

struct UserUpdateEmailAccountTemplate: MailTemplateRepresentable {
    let mail: Mail
    
    init(user: UserAccountModel, oldEmail: String) throws {
        let recipient = MailUser(name: user.name, email: user.email)
        let oldEmailRecipient = MailUser(name: user.name, email: oldEmail)
        let subject = "Neue E-Mail-Adresse"
        guard let userToken = user.verificationToken?.value else {
            throw Abort(.internalServerError)
        }
        let verificationLink = "\(Environment.appUrl)/api/user/accounts/\(user.id!)/verify?token=\(userToken)"
        let text = """
        Hallo \(user.name),
        
        Deine E-Mail-Adresse wurde soeben geändert. Bitte bestätige mit dem folgenden Link deine neue E-Mail-Adresse:
        \(verificationLink)
        
        Sobald deine neue E-Mail-Adresse bestätigt ist, kannst du Orte erstellen und Medien hochladen.
        
        Falls du die E-Mail nicht geändert hast, überprüfe bitte deine Account-Einstellungen und ändere dein Passwort.
        
        Wir wünschen dir viel Spaß und hoffen, dass du neue Einblicke erhalten kannst.
        
        Dein Footprints for Freedom Team
        
        Diese E-Mail wurde automatisch erstellt. Bitte antworte nicht an diese Adresse.
        """
        
        // TODO: embed iOS-App link
        // P.S.: Du willst auch unterwegs informiert bleiben? Footprints for Freedom gibt es auch als iOS-App. Lad sie dir am besten gleich runter!
        
        self.mail = Mail(
            from: MailDefaults.sender,
            to: [recipient, oldEmailRecipient],
            subject: subject,
            contentType: .plain,
            text: text
        )
        
        // TODO: make sure only verified user can create media and waypoint
    }
    
    func sendAction(_ req: Request) async throws {
        try await req.application.sendMail(mail, withCredentials: .default).get()
    }
}
