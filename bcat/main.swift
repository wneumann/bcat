//
//  main.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

// Based on the code found here https://rderik.com/blog/building-a-server-client-aplication-using-apple-s-network-framework/
// Hoping to extend it soon

import Foundation

guard #available(macOS 10.14, *) else {
    FileHandle.standardError.write("Requires macOS 10.14 or newer".data(using: .utf8)!)
    exit(EXIT_FAILURE)
}

// MARK: Defaults
var isServer = false
var portNumber: UInt16 = 4444
var serverAddr = "localhost"

// MARK: Parse options
let usage = """
Usage:
bcat [-lh?] [serverAddr] port
-h, -?      help
-l          listen (server) mode
port        port number (default 4444)
            if 0, port will be assign by the system

"""

func die(_ msg: String, err: Int32 = 1) -> Never {
    fputs(msg, stderr)
    exit(err)
}

guard CommandLine.argc > 1 else { die(usage) }

while case let opt = getopt(CommandLine.argc, CommandLine.unsafeArgv, "lh?"), opt != -1 {
    switch UnicodeScalar(CUnsignedChar(opt)) {
    case "l": isServer = true
    case "h", "?": die(usage, err: 0)
    default: die("Unknown option: -\(UnicodeScalar(CUnsignedChar(opt)))\n\n\(usage)")
    }
}

var dropOpts = CommandLine.arguments.suffix(from: Int(optind))
if !isServer {
    guard dropOpts.count > 1 else { die("Error: client mode requires server address and port") }
    serverAddr = dropOpts.popFirst()!
}
if let pPort = dropOpts.first {
    if let iPort = UInt16(pPort) {
        portNumber = iPort
        guard !(1...1024 ~= portNumber) || NSUserName() == "root" else {
            die("Port number (\(portNumber)) requires root to use.\n\n\(usage)")
        }
    } else {
        die("invalid port number (\(pPort))\n\n\(usage)")
    }
}

// MARK: Functionality

if isServer {
    print("Starting as server, listening on port \(portNumber)")
    let server = Server(options: ServerOptions(port: portNumber))
    try! server.startListner()
} else {
    print("Starting as client, connecting to server at \(serverAddr):\(portNumber)")
    let client = Client(options: ClientOptions(port: portNumber, serverAddr: serverAddr))
    client.start()
}






// MARK: RunLoop
RunLoop.current.run()
