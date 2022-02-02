//
//  UserCreateAccountTemplate.swift
//  
//
//  Created by niklhut on 01.02.22.
//

import Vapor
import SMTPKitten

struct UserCreateAccountTemplate: MailTemplateRepresentable {
    let mail: Mail
    
    init(user: UserAccountModel) throws {
        let recipient = MailUser(name: user.name, email: user.email)
        let subject = "Dein neuer Footprints for Freedom Account"
        guard let userToken = user.verificationToken?.value else {
            throw Abort(.internalServerError)
        }
        let verificationLink = "\(Environment.appUrl)/api/user/accounts/\(user.id!)/verify?token=\(userToken)"
        let text = """
        Hallo \(user.name),
        
        willkommen bei Footprints for Freedom.
        
        Du hast dich erfolgreich angemeldet. Bitte bestätige mit dem folgendne Link deine E-Mail-Adresse:
        \(verificationLink)
        
        Sobald deine E-Mail-Adresse bestätigt ist, kannst du Orte erstellen und Medien hochladen.
        
        Wir wünschen dir viel Spaß und hoffen, dass du neue Einblicke erhalten kannst.
        
        Dein Footprints for Freedom Team
                
        Diese E-Mail wurde automatisch erstellt. Bitte antworte nicht an diese Adresse.
        """
        
        // TODO: embed iOS-App link
        // P.S.: Du willst auch unterwegs informiert bleiben? Footprints for Freedom gibt es auch als iOS-App. Lad sie dir am besten gleich runter!
        
        self.mail = Mail(
            from: MailDefaults.sender,
            to: [recipient],
            subject: subject,
            contentType: .plain,
            text: text
        )
        
        // TODO: make sure only verified user can create media and waypoint
    }
    
    func send(on req: Request) async throws {
        try await req.application.sendMail(mail, withCredentials: .default).get()
    }
}
