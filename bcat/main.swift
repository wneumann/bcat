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
var ipV4 = false
var ipV6 = false
var ipVer: Int? = nil

// MARK: Parse options
let usage = """
Usage:
bcat [-lh?] [serverAddr] port
-h, -?      help
-l          listen (server) mode
port        port number (default 4444)
            if 0, port will be assign by the system

"""

//func log(_ msg: String) {
//    fputs(msg, stderr)
//}
//
//func die(_ msg: String, err: Int32 = 1) -> Never {
//    log(msg)
//    exit(err)
//}

var log = Logger()

guard CommandLine.argc > 1 else { log.die(usage) }

while case let opt = getopt(CommandLine.argc, CommandLine.unsafeArgv, "lh?46v"), opt != -1 {
    switch UnicodeScalar(CUnsignedChar(opt)) {
    case "l": isServer = true
    case "h", "?": log.die(usage, err: 0)
    case "4": ipV4 = true
    case "6": ipV6 = true
    case "v": log.increaseVerbosity()
    default: log.die("Unknown option: -\(UnicodeScalar(CUnsignedChar(opt)))\n\n\(usage)")
    }
}

// MARK: Validate options

var dropOpts = CommandLine.arguments.suffix(from: Int(optind))
if !isServer {
    guard dropOpts.count > 1 else { log.die("Error: client mode requires server address and port") }
    serverAddr = dropOpts.popFirst()!
}
if let pPort = dropOpts.first {
    if let iPort = UInt16(pPort) {
        portNumber = iPort
        guard !isServer || !(1...1024 ~= portNumber) || NSUserName() == "root" else {
            log.die("Port number (\(portNumber)) requires root to use.\n\n\(usage)")
        }
    } else {
        log.die("invalid port number (\(pPort))\n\n\(usage)")
    }
}

if ipV4 != ipV6 {
    if ipV4 { ipVer = 4 } else { ipVer = 6 }
} else {
    if ipV6 { log.log("Both IPv4 and IPv6 selected, accepting any", level: .info) }
}
// MARK: Functionality

if isServer {
    log.log("Starting as server, listening on port \(portNumber)", level: .warning)
    let server = Server(options: ServerOptions(port: portNumber, ipVersion: ipVer), logger: log)
    try! server.startListner()
} else {
    log.log("Starting as client, connecting to server at \(serverAddr):\(portNumber)", level: .warning)
    let client = Client(options: ClientOptions(port: portNumber, serverAddr: serverAddr, ipVersion: ipVer), logger: log)
    client.start()
}


// MARK: RunLoop
RunLoop.current.run()
