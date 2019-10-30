//
//  main.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

import Foundation

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

func die(_ msg: String) -> Never {
    fputs(msg, stderr)
    exit(1)
}

guard CommandLine.argc > 1 else { die(usage) }

while case let opt = getopt(CommandLine.argc, CommandLine.unsafeArgv, "lh?"), opt != -1 {
    switch UnicodeScalar(CUnsignedChar(opt)) {
    case "l": isServer = true
    case "h", "?": die(usage)
    default: die("Unknown option: -\(UnicodeScalar(CUnsignedChar(opt)))\n\n\(usage)")
    }
}

var dropOpts = CommandLine.arguments.suffix(from: Int(optind))
if !isServer {
    guard dropOpts.count > 1 else { die("Error: client mode requires server address and port") }
    serverAddr = dropOpts.popFirst()!
}
if let pPort = dropOpts.first, let iPort = UInt16(pPort) {
    portNumber = iPort
} else {
    die("invalid port number (\(pPort))\n\n\(usage)")
}
guard !(1...1024 ~= portNumber) || NSUserName() == "root" else {
    die("Port number (\(portNumber)) requires root to use.\n\n\(usage)")
}
if isServer {
    print("Starting as server, listening on port \(portNumber)")
} else {
    print("Starting as client, connecting to server at \(serverAddr):\(portNumber)")
}






// MARK: RunLoop
RunLoop.current.run()
