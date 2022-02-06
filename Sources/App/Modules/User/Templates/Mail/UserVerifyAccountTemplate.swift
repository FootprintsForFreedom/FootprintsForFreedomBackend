//
//  UserVerifyAccountTemplate.swift
//  
//
//  Created by niklhut on 02.02.22.
//

import Vapor
import SMTPKitten

struct UserVerifyAccountTemplate: MailTemplateRepresentable {
    
    let mail: Mail
    
    init(user: UserAccountModel) throws {
        let recipient = MailUser(name: user.name, email: user.email)
        let subject = "Bitte verifiziere deinen Footprints for Freedom Account"
        guard let userToken = user.verificationToken?.value else {
            throw Abort(.internalServerError)
        }
        let verificationLink = "\(Environment.appUrl)/api/user/accounts/\(user.id!)/verify?token=\(userToken)"
        let text = """
        Hallo \(user.name),
        
        Vielen Dank, dass du Footprints for Freedom verwendest. Bitte bestätige mit dem folgenden Link deine E-Mail-Adresse:
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
    }
    
    func sendAction(_ req: Request) async throws {
        try await req.application.sendMail(mail, withCredentials: .default).get()
    }
}
