//
//  Server.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

/// Server class for managing multiple connections. The individual connections themselves will be managed by the ServerConnection class.

import Foundation
import Network

@available(macOS 10.14, *)

// TODO: Add actual error handling

class Server {
    let port: NWEndpoint.Port
    let listner: NWListener
    let log: Logger
    
    private var connectionsByID: [Int: ServerConnection] = [:]
    
    init(options: ServerOptions, logger: Logger) {
        self.port = NWEndpoint.Port(rawValue: options.port)!
        let params = NWParameters.tcp.copy()
        if let ipV = options.ipVersion {
            (params.defaultProtocolStack.internetProtocol as! NWProtocolIP.Options).version = ipV == 4 ? .v4 : .v6
        }
        //print("listener has IPOption.version \((params.defaultProtocolStack.internetProtocol as! NWProtocolIP.Options).version)")
        self.listner = try! NWListener(using: params, on: self.port)
        log = logger
    }
    
    func startListner() throws {
        log.log("Starting server", level: .info)
        listner.stateUpdateHandler = self.stateDidChange(to:)
        listner.newConnectionHandler = self.didAcceptConnection(from:)
        listner.start(queue: .main)
    }
    
    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            log.log("Server \(listner) ready for connections", level: .info)
        case .failed(let error):
            print("Server failure; \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        case .cancelled:
            log.elog("Server cancelled, shutting down", level: .warning)
        default:
            break
        }
    }
    
    private func didAcceptConnection(from connection: NWConnection) {
        let conn = ServerConnection(connection: connection, logger: log)
        self.connectionsByID[conn.id] = conn
        conn.didStopCallback = { _ in self.connectionDidStop(conn) }
        conn.start()
        conn.send(data: "¡Hola, connexion! You are #\(conn.id).\n".data(using: .utf8)!)
        log.log("Server accepted connection #\(conn.id)", level: .warning)
    }
    
    private func connectionDidStop(_ connection: ServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        log.log("Server closed connection #\(connection.id)", level: .warning)
    }
    
    private func stop() {
        self.listner.stateUpdateHandler = nil
        self.listner.newConnectionHandler = nil
        self.listner.cancel()
        for connection in self.connectionsByID.values {
            connection.didStopCallback = nil
            connection.stop()
        }
        self.connectionsByID.removeAll()
    }
}
