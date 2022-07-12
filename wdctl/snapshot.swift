//
//  snapshot.swift
//  wdctl
//
//  Created by Xiao Jin on 2021/8/14.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import ArgumentParser

struct snapshot: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "system info snapshotter")
    
    func run() throws {
        var results = [String: Any]()
        if let ps = ps() {
            results["ps"] = ps
        }
        if let temperature = sensor(.temperature) {
            results["temperature"] = temperature
        }
        if let summary = summary() {
            results["summary"] = summary
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: results, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        
        print(json)
    }
    
}
