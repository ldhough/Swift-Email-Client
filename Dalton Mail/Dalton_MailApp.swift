//
//  Dalton_MailApp.swift
//  Dalton Mail
//
//  Created by Lannie Hough on 3/17/21.
//

import SwiftUI

@main
struct Dalton_MailApp: App {
    
    init() {
        print("App initialized!")
        setenv("CFNETWORK_DIAGNOSTICS", "3", 1)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
