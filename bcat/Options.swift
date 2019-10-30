//
//  Options.swift
//  bcat
//
//  Created by Will Neumann on 10/30/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

import Foundation

protocol  Options {
    var port: UInt16 { get }
}

struct ServerOptions: Options {
    var port: UInt16
}
struct ClientOptions: Options {
    var port: UInt16
    let serverAddr: String
}
