//
//  LoginView.swift
//  Dalton Mail
//
//  Created by Lannie Hough on 3/24/21.
//

import SwiftUI
import SwiftSMTP

class SMTPModel {
    var email:String?
    var smtp:SMTP?
}

struct LoginView: View {
    
    let smtpModel:SMTPModel
    
    @State var email = ""
    @State var password = ""
    
    @State var alertMessage = ""
    @State var showAlert = false
    
    @Binding var loginSucceeded:Bool
    
    @State var provider = "gmail"
    
    let supportedEmailsList = ["gmail", "outlook"]
    let supportedEmails:[String:(String, Int32)] = [
        "gmail": ("smtp.gmail.com", 587),
        "outlook": ("smtp.live.com", 587)
    ]
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    Spacer()
                    Text("Dalton Mail").font(.title).foregroundColor(.orange)
                    Spacer()
                }
                TextField("Email", text: $email).padding()
                SecureField("Password", text: $password).padding([.bottom, .leading, .trailing])
                HStack {
                    Spacer()
                    Button(action: {
                        check: if !isValid(email: email) {
                            showAlert = true
                            alertMessage = "Invalid email address!"
                        } else {
                            let hostname:String = supportedEmails[provider]!.0
                            let smtp = SMTP(hostname: hostname,
                                            email: email,
                                            password: password,
                                            port: supportedEmails[provider]!.1,
                                            tlsMode: .requireSTARTTLS)
                            smtpModel.smtp = smtp
                            smtpModel.email = email
                            loginSucceeded = true
                        }
                    }) {
                        Text("Login")
                    }
                    Spacer()
                }.alert(isPresented: $showAlert) {
                    Alert(title: Text("Error!"), message: Text(alertMessage), dismissButton: .default(Text("Dismiss")))
                }
                Spacer()
            }
        }
    }
    
    func isValid(email: String) -> Bool {
        return (email.countOf(char: "@") == 1 && email.countOf(char: ".") == 1)
//            && !(email[email.startIndex] == "@" || email[email.endIndex] == "@")
//            && !(email[email.startIndex] == "." || email[email.endIndex] == ".")
    }
}
