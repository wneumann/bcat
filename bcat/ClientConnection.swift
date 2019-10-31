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
    let log: Logger
    
    init(connection: NWConnection, logger: Logger) {
        self.connection = connection
        self.log = logger
    }
    

    
    func stateDidChange(to newState: NWConnection.State) {
        switch newState {
            
        case .waiting(let error), .failed(let error):
            connectionDidFail(error: error)
        case .ready:
            log.log("Client is ready", level: .info)
        case .cancelled:
            log.log("--Cancelling client connection", level: .warning)
        default:
            log.log("I unno? State: \(newState)", level: .info)
            break
        }
    }
    func setupReceive() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: Int(Int16.max)) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8) ?? "--not utf8 text--"
                let msg = String(message.reversed().drop(while: { $0 == "\n" }).reversed())
                self.log.log("Client connection received \(data) [\(msg)]", level: .info)
                print("echo: \(msg)")
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
        log.log("Starting client connection", level: .warning)
        connection.stateUpdateHandler = stateDidChange(to:)
        setupReceive()
        connection.start(queue: queue)
    }
    func run() {
        print("Echo client running: type \"QUIT\" to exit")
        while true {
            guard var command = readLine(strippingNewline: true) else {
                log.log("^D received, shutting down client", level: .warning)
                self.sendEndOfStream()
                exit(EXIT_SUCCESS)
            }
            switch command {
            case "CRLF": command = "\r\n"
            case "LF": command = "\n"
            case "QUIT": self.stop(error: nil)
            default:
                break
            }
            self.send(data: command.data(using: .utf8)!)
        }
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
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            self.log.log("Client sent \(data).", level: .info)
        }))
    }
    func sendEndOfStream() {
        connection.send(content: nil, contentContext: .defaultStream, isComplete: true, completion: .contentProcessed({ error in
            if let error = error {
                self.connectionDidFail(error: error)
            }
        }))
        self.stop(error: nil)
    }
    func connectionDidFail(error: Error) {
        log.elog("Client connection failed with error: \(error.localizedDescription)", level: .error)
        self.stop(error: error)
    }
    func connectionDidEnd() {
        log.log("Client connection ended normally", level: .warning)
        self.stop(error: nil)

    }
}
