//
//  Client.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

import Foundation
import Network

@available(macOS 10.14, *)

class Client{
    let connection: ClientConnection
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    let log: Logger
    
    init(options: ClientOptions, logger: Logger) {
        self.host = NWEndpoint.Host(options.serverAddr)
        self.port = NWEndpoint.Port(rawValue: options.port)!
        log = logger
        let params = NWParameters.tcp.copy()
        if let ipV = options.ipVersion {
            (params.defaultProtocolStack.internetProtocol as! NWProtocolIP.Options).version = ipV == 4 ? .v4 : .v6
        }
        //print("connection has IPOption.version \((params.defaultProtocolStack.internetProtocol as! NWProtocolIP.Options).version)")
        let conn = NWConnection(host: host, port: port, using: params)
        //print("Connection \(conn) created")
        connection = ClientConnection(connection: conn, logger: log)
    }
    
    func start() {
        log.log("Starting client; connecting to \(host):\(port)", level: .info)
        connection.didStopCallback = didStopCallback(error:)
        connection.start()
        connection.run()
    }
    private func stop() {
        connection.stop(error: nil)
    }
    private func send(data: Data) {
        connection.send(data: data)
    }
    
    func didStopCallback(error: Error?) {
        exit(error == nil ? EXIT_SUCCESS : EXIT_FAILURE)
    }
}
