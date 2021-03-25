//
//  Dalton_MailApp.swift
//  Dalton Mail
//
//  Created by Lannie Hough on 3/17/21.
//

import SwiftUI
import SwiftSMTP

@main
struct Dalton_MailApp: App {
    
    @State var loginSucceeded = false
    let smtpModel:SMTPModel
    
    init() {
        print("App initialized!")
        smtpModel = SMTPModel()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !loginSucceeded {
                    LoginView(smtpModel: smtpModel, loginSucceeded: $loginSucceeded)
                } else {
                    MailView(smtpModel: smtpModel)
                }
            }.frame(width: 400, height: 600, alignment: .center)
        }
    }
}
