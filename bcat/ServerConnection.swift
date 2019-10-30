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
    private var nextID = 1
    let id: Int
    var didStopCallback: (Error) -> () = { _ in return }
    let connection: NWConnection
    
    init(connection: NWConnection) {
        id = nextID
        nextID += 1
        self.connection = connection
    }
    
    func start() {
        
    }
    func send(data: Data) {
        
    }
}
