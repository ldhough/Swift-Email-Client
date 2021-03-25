//
//  MailView.swift
//  Dalton Mail
//
//  Created by Lannie Hough on 3/25/21.
//

import SwiftUI
import SwiftSMTP

struct MailView: View {
    
    let smtpModel:SMTPModel
    @State var emailBody = ""
    @State var emailSubject = ""
    @State var to = ""
    @State var cc = ""
    
    @State var isError = false
    @State var showAlert = false
    @State var alertMsg = ""
    
    @State var attachments:[Attachment] = []
    
    var body: some View {
        Form {
            Section(header: Text("Subject")) {
                TextField("", text: $emailSubject)
            }
            Section(header: Text("Send to")) {
                TextField("", text: $to)
            }
            Section(header: Text("CC")) {
                TextField("", text: $cc)
            }
            Section(header: Text("Attachments")) {
                ImageDragDrop(attachments: $attachments).padding()
            }
            Section(header: Text("Email message")) {
                TextEditor(text: $emailBody)
            }
            HStack {
                Spacer()
                Section(header: EmptyView()) {
                    Button(action: {
                        let mail = Mail(
                            from: Mail.User(name: "", email: smtpModel.email ?? ""),
                            to: [Mail.User(name: "", email: to)],
                            cc: cc.split(",").remap { str in
                                return Mail.User(name: "", email: str)
                            },
                            subject: emailSubject,
                            text: emailBody,
                            attachments: attachments
                        )
                        smtpModel.smtp?.send(mail) { error in
                            if let error = error {
                                print("ERROR SENDING MAIL: ")
                                print(error)
                                isError = true
                                alertMsg = "Could not send mail! \(error)"
                                showAlert = true
                            } else {
                                isError = false
                                alertMsg = "Email sent!"
                                showAlert = true
                            }
                        }
                    }) {
                        Text("Send email")
                    }.alert(isPresented: $showAlert) {
                        Alert(title: Text(isError ? "Error!" : "Success!"), message: Text(alertMsg), dismissButton: .default(Text("Dismiss")))
                    }
                }
                Spacer()
            }.padding()
        }
    }
}

extension Array {
    func remap<T>(_ toAppend: (Element) -> T) -> [T] {
        var newArray:[T] = []
        for element in self {
            newArray.append(toAppend(element))
        }
        return newArray
    }
}

extension String {
    
    func countOf(char: Character) -> Int {
        var count = 0
        for c in self {
            count = c == char ? count + 1 : count
        }
        return count
    }
    
    func split(_ on: Character) -> [String] {
        var strings:[String] = []
        var newStr = ""
        loop: for char in self {
            if char == on {
                if newStr == "" {
                    continue loop
                } else {
                    strings.append(newStr)
                    newStr = ""
                }
            } else {
                newStr += String(char)
            }
        }
        if newStr != "" {
            strings.append(newStr)
        }
        return strings
    }
    
}


//Copied with small edits from @Asperi's answer on https://stackoverflow.com/questions/60831260/swiftui-drag-and-drop-files
struct ImageDragDrop: View {
    @State var image = NSImage(systemSymbolName: "link", accessibilityDescription: nil)
    @State private var dragOver = false
    @Binding var attachments:[Attachment]

    var body: some View {
        Image(nsImage: image ?? NSImage())
            .resizable()
            .frame(width: 50, height: 50, alignment: .center)
            .onDrop(of: ["public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                providers.first?.loadDataRepresentation(forTypeIdentifier: "public.file-url", completionHandler: { (data, error) in
                    if let data = data, let path = NSString(data: data, encoding: 4), let url = URL(string: path as String) {
                        let dataAttachment = Attachment(
                            data: data,
                            mime: "application/image",
                            name: path as String + ".png",
                            // send as a standalone attachment
                            inline: false
                        )
                        attachments.append(dataAttachment)
                        let image = NSImage(contentsOf: url)
                        DispatchQueue.main.async {
                            self.image = image
                        }
                    }
                })
                return true
            }
            .onDrag {
                let data = self.image?.tiffRepresentation
                let provider = NSItemProvider(item: data as NSSecureCoding?, typeIdentifier: kUTTypeTIFF as String)
                provider.previewImageHandler = { (handler, _, _) -> Void in
                    handler?(data as NSSecureCoding?, nil)
                }
                return provider
            }
            .border(dragOver ? Color.red : Color.clear)
            
    }
}

