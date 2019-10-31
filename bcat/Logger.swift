//
//  Logger.swift
//  bcat
//
//  Created by Will Neumann on 10/31/19.
//  Copyright © 2019 Will Neumann. All rights reserved.
//

import Foundation

enum Level: Int {
    case error = 0, warning, info
}

//enum Channel {
//    case standard, error
//}

struct StderrOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

var standardError = StderrOutputStream()

class Logger {
    public private(set) var verbosity: Int
    
    init(verbosity: Int = 0) {
        self.verbosity = verbosity
    }
    
    func increaseVerbosity() {
        verbosity += 1
    }
    
    func log(_ msg: String, level: Level = .error) {
        if level.rawValue <= verbosity { print(msg) }
    }
    
    func elog(_ msg: String, level: Level = .error) {
        let header = level == .error ? "Error: " : level == .warning ? "Warning: " : ""
        if level.rawValue >= verbosity { print("\(header)msg", to: &standardError) }
    }
    
    func die(_ msg: String, err: Int32 = 1) -> Never {
        elog(msg, level: .error)
        exit(err)
    }
}
