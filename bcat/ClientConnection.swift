//
//  ClientConnection.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//


import Foundation
import Network

@available(macOS 10.14, *)

class ClientConnection {
    let connection: NWConnection
    var didStopCallback: ((Error?) -> ())? = nil
    let queue = DispatchQueue(label: "clientQ")
    
    init(connection: NWConnection) {
        self.connection = connection
    }
    

    
    func stateDidChange(to newState: NWConnection.State) {
        switch newState {
            
        case .waiting(let error), .failed(let error):
            connectionDidFail(error: error)
        case .ready:
            print("Client is ready")
        case .cancelled:
            print("--Cancelling client connection")
        default:
            break
        }
    }
    func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(Int16.max)) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? "--not utf8 text--"
                let msg = String(message.reversed().drop(while: { $0 == "\n" }).reversed())
                print("Client connectionm received \(data) [\(msg)]")
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
    
    func start() {
        print("Starting client connection")
        connection.stateUpdateHandler = stateDidChange(to:)
        setupReceive()
        connection.start(queue: queue)
    }
    func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = self.didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
    func send(data: Data) {
        
    }
    func connectionDidFail(error: Error) {
        print("Client connection failed with error: \(error.localizedDescription)")
        self.stop(error: error)
    }
    func connectionDidEnd() {
        print("Client connection ended normally")
        self.stop(error: nil)

    }
}
