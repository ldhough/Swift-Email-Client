//
//  ContentView.swift
//  Dalton Mail
//
//  Created by Lannie Hough on 3/17/21.
//

import SwiftUI

var smtpC:SMTPConnection?

struct ContentView: View {
    @State var msg = "Hello, world!"
    
    var body: some View {
        VStack {
            Text(msg)
                .padding()
            Button(action: {
                print("Pressed button")
                let message = Message(from: "lanniehough@lannies-macbook-pro.local", to: "ldhough@stetson.edu", subject: "A test thing", body: "Please work")
                let env = Envelope(message: message, server: "http://smtp.live.com")
                if let e = env {
                    let smtpc = SMTPConnection(envelope: e) { _ in
                        
                    }
                    smtpC = smtpc
                } else {
                    print("Sad times")
                }
            }) {
                Text("PRESS ME TO TEST")
            }.padding()
            Button(action: {
                smtpC!.tryReadThing()
            }) {
                Text("PRESS ME TO TEST MORE")
            }
        }.frame(width: 400, height: 400, alignment: .center) //VStack end
    }
}
