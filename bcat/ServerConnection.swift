//
//  ServerConnection.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

import Foundation
import Network

@available(macOS 10.14, *)
class ServerConnection {
    private static var nextID = 1
    let id: Int
    var didStopCallback: ((Error?) -> ())? = nil
    let connection: NWConnection
    
    init(connection: NWConnection) {
        id = ServerConnection.nextID
        ServerConnection.nextID += 1
        self.connection = connection
    }
    
    func start() {
        print("\tConnection \(id) will start")
        connection.stateUpdateHandler = self.stateDidChange(to:)
        setupReceive()
        connection.start(queue: .main)
    }
    func stop() {
        print("\tConnection \(id) will stop.")
    }
    private func stop(error: Error?) {
        connection.stateUpdateHandler = nil
        connection.cancel()
        if let didStopCallback = didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
    func send(data: Data) {
        self.connection.send(content: data, completion: .contentProcessed({ (error) in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            print("\tConnection \(self.id) sent \(data)")
        }))
    }
    
    func stateDidChange(to newState: NWConnection.State) {
        switch newState {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("\tConnetion \(id) is ready")
        case .failed(let error):
            connectionDidFail(error: error)
        case .cancelled:
            print("\tConnection \(id) cancelled, shutting down")
        default:
            break
        }
    }
    
    func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(Int16.max)) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? "--not utf8 text--"
                let msg = String(message.reversed().drop(while: { $0 == "\n" }).reversed())
                print("\tConnection \(self.id) received \(data) [\(msg)]")
                self.send(data: data)
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
    
    func connectionDidEnd() {
        print("\tConnection \(id) ended.")
        stop(error: nil)
    }
    func connectionDidFail(error: Error) {
        print("\tConnection \(id) failed with error \(error.localizedDescription).")
        stop(error: error)
    }
}
