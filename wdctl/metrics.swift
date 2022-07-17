//
//  metrics.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/14.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import ArgumentParser
import Shared

struct metrics: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "system info metrics")
    
    func run() throws {
        var metrics = WDMetrics()
        metrics.CPUUsage = collectCPUUsage()
        metrics.memUsage = collectMemUsage()
        metrics.processes = collectProcesses()
        metrics.sensors = collectSensors()
        
        guard let data = metrics.encode(),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        
        print(string)
    }
    
}
