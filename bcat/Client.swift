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
    
    init(options: ClientOptions) {
        self.host = NWEndpoint.Host(options.serverAddr)
        self.port = NWEndpoint.Port(rawValue: options.port)!
        let conn = NWConnection(host: host, port: port, using: .tcp)
        connection = ClientConnection(connection: conn)
    }
    
    func start() {
        print("Starting client; connecting to \(host):\(port)")
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
