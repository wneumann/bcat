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
    
    private var connectionsByID: [Int: ServerConnection] = [:]
    
    init(options: ServerOptions) {
        self.port = NWEndpoint.Port(rawValue: options.port)!
        self.listner = try! NWListener(using: NWParameters.tcp, on: self.port)
    }
    
    func startListner() throws {
        print("Starting server")
        listner.stateUpdateHandler = self.stateDidChange(to:)
        listner.newConnectionHandler = self.didAcceptConnection(from:)
        listner.start(queue: .main)
    }
    
    func stateDidChange(to newState: NWListener.State) {
        switch newState {
        case .ready:
            print("Server ready for connections")
        case .failed(let error):
            print("Server failure; \(error.localizedDescription)")
            exit(EXIT_FAILURE)
        case .cancelled:
            print("Server cancelled, shutting down")
        default:
            break
        }
    }
    
    private func didAcceptConnection(from connection: NWConnection) {
        let conn = ServerConnection(connection: connection)
        self.connectionsByID[conn.id] = conn
        conn.didStopCallback = { _ in self.connectionDidStop(conn) }
        conn.start()
        conn.send(data: "¡Hola, connexion! You are #\(conn.id).\n".data(using: .utf8)!)
        print("Server accepted connection #\(conn.id)")
    }
    
    private func connectionDidStop(_ connection: ServerConnection) {
        self.connectionsByID.removeValue(forKey: connection.id)
        print("Server closed connection #\(connection.id)")
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
