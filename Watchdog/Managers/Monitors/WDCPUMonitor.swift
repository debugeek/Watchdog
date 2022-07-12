//
//  WDCPUMonitor.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

class WDCPUMonitor: WDMonitor {
    
    override func process(_ snapshot: WDSnapshot) {
        guard let processes = snapshot.processes, processes.count > 0 else { return }
        
        for (_, context) in contexts {
            var ids = [String]()

            for process in processes {
                if process.cpu < context.strategy.threshold {
                    continue
                }

                ids.append(process.name)
            }

            context.update(ids)
        }
    }
    
    override func notify(_ context: WDStrategyContext, _ ids: [String]) {
        for id in ids {
            WDNotificationCenter.shared.notify(title: "\(id)", body: "CPU usage above \(context.strategy.threshold)% over \(context.strategy.duration)s")
        }
    }
    
}
