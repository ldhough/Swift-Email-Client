//
//  SMTP.swift
//  Dalton Mail
//
//  Created by Lannie Hough on 3/21/21.
//

import Foundation
import Network

struct Message {
    
    let headers:String
    let body:String
    
    let from:String
    let to:String
    
    init(from: String, to: String, subject: String, body: String) {
        
        self.from = from.trimmingCharacters(in: .whitespaces)
        self.to = to.trimmingCharacters(in: .whitespaces)
        
        var head = "From: " + self.from + "\r\n";
        head += "To: " + self.to + "\r\n";
        head += "Subject: " + subject.trimmingCharacters(in: .whitespaces) + "\r\n";
        
        let date = Date()
        let ds = date.dateAsString(withFormat: "EEE, dd MMM yyyy HH:mm:ss 'GMT'")
        head += "Date: " + ds + "\r\n"
        
        self.headers = head
        self.body = { //escape single periods
            var body = ""
            let lines = body.split("\n")
            for line in lines {
                if line[line.startIndex] == "." {
                    body += "." + line
                } else {
                    body += line
                }
            }
            return body
        }()
    }
    
    //Check that sender and recipient address contain a single @ sign
    func isValid() -> (Bool, String?) {
        var errStr:String?
        if from.countOf(char: "@") != 1 || (from[from.startIndex] == "@" || from[from.endIndex] == "@") {
            errStr = "Sender address is invalid!"
        }
        if to.countOf(char: "@") != 1 || (to[to.startIndex] == "@" || to[to.endIndex] == "@") {
            let es = "Recipient address is invalid!"
            errStr = errStr == nil ? es : errStr! + "\n\(es)"
        }
        return (errStr == nil, errStr)
    }
    
}

struct Envelope {
    
    let sender:String
    let recipient:String
    
    let host:String
    let mailserverAddr:IPv4Address
    
    init?(message: Message, server: String) {
        self.sender = message.from
        self.recipient = message.to
        self.host = server
        guard let mailserverAddr = IPv4Address(urlToIP(URL(string: server)) ?? "") else {
            print("Error in getting IP from server!")
            return nil
        }
        self.mailserverAddr = mailserverAddr
    }
    
}

class SMTPConnection: NSObject, StreamDelegate {
    
    static let SMTP_PORT = 587
    static let BUFF_CAP = 4096
    
    var inputStream:InputStream?
    var outputStream:OutputStream?
    
    init?(envelope: Envelope, _ errorCompletion: (String?) -> Void) {
        super.init()
        
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           urlToIP(URL(string: envelope.host)) as CFString?, //"127.0.0.1" as CFString,//
                                           UInt32(SMTPConnection.SMTP_PORT),
                                           &readStream,
                                           &writeStream)
        
        self.inputStream = readStream?.takeRetainedValue()
        self.outputStream = writeStream?.takeRetainedValue()
        
        inputStream?.delegate = self
        outputStream?.delegate = self
        
        inputStream?.schedule(in: .current, forMode: .common)
        outputStream?.schedule(in: .current, forMode: .common)
        
        inputStream?.open()
        outputStream?.open()
        
//        sleep(5)
//        if let ist = inputStream {
//            let reply = readBytes(stream: ist)
//            print("Reply is: \(String(describing: reply))")
//        } else {
//            print("Error reading input stream")
//        }
//
//        self.writeBytesOfCommand(withString: "HELO " + "localhost", withExpectedResponse: 250)
//        while CFReadStreamGetStatus(inputStream) != .open { print("SPINNING") }
//        tryReadThing()
    }
    
    func
    
//    func tryReadThing() {
//        if let ist = inputStream {
//            let reply = readBytes(stream: ist)
//            print("Reply is: \(String(describing: reply))")
//        } else {
//            print("Error reading input stream")
//        }
//    }
    
    private func writeBytesOfCommand(withString: String, withExpectedResponse: Int) {
        let d = withString.data(using: .utf8)
        guard let data = d else {
            print("Error making data in writeBytesOfCommand()")
            return
        }
        data.withUnsafeBytes {
            print("Withunsafebytes")
            guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                print("Error writing data!")
                return
            }
            print(pointer.pointee)
            print(data.count)
            if let os = outputStream {
            if os.hasSpaceAvailable {
                print("Space available to write!")
                outputStream?.write(pointer, maxLength: data.count)
                print("Tried to write with string: \(withString)")
            } else { print("No space to write!") }
            }
        }
        if let inS = inputStream {
            let reply = self.readBytes(stream: inS)
            print("Reply from write attempt is: \(reply)")
        }
    }
    
    private func readBytes(stream: InputStream) -> String? {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: SMTPConnection.BUFF_CAP)
        while stream.hasBytesAvailable {
            print("Bytes are available to read!")
            let numBytesRead = stream.read(buffer, maxLength: SMTPConnection.BUFF_CAP)
            if numBytesRead < 0, let error = stream.streamError {
                print(error)
                break
            }
            print("BUFFER IS: \(buffer.pointee)")
            let str = self.processBufferToString(buffer, len: numBytesRead)
            return str
        }
        return nil
    }
    
    private func processBufferToString(_ buffer: UnsafeMutablePointer<UInt8>, len: Int) -> String? {
        return printr(String(bytesNoCopy: buffer, length: len, encoding: .utf8, freeWhenDone: true), "PROCESSED IS: ")
    }
    
    //Get smtp response code from reply
    private func parseReply(_ reply: String) -> Int? {
        return Int(reply.split(" ")[0])
    }
    
}

func urlToIP(_ url: URL?) -> String? {
    print(url?.absoluteString)
    guard let url = url else {
        print("Error w/ URL object")
        return nil
    }
    guard let hostname = url.host else {
        print("Error w/ url.host")
        return nil
    }
    guard let host = hostname.withCString({gethostbyname($0)}) else {
        print("Error in .withCString()")
        return nil
    }
    guard host.pointee.h_length > 0 else {
        print("Error with host.pointee.h_length")
        return nil
    }
    var addr = in_addr()
    memcpy(&addr.s_addr, host.pointee.h_addr_list[0], Int(host.pointee.h_length))
    guard let remoteIPAsC = inet_ntoa(addr) else {
        print("Error in inet_ntoa()")
        return nil
    }
    return printr(String.init(cString: remoteIPAsC), "IP is: ")
}

extension Date {
    
    func dateAsString(withFormat: String, _ withLocaleString: String = "en_US") -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: withLocaleString)
        df.dateFormat = withFormat
        return df.string(from: self)
    }
    
}

//Print some object and return it, useful for debugging
func printr<T>(_ thing: T, _ additionalInfo: String = "") -> T {
    print(additionalInfo + "\(thing)")
    return thing
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
