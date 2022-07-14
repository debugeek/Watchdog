//
//  WDMemoryMonitor.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/16.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import Shared

class WDMemoryMonitor: WDMonitor {
    
    override func process(_ metrics: WDMetrics) {
        guard let memUsage = metrics.memUsage else {
            return
        }
        
        let percent = memUsage.used/(memUsage.used + memUsage.free)*100.0
        
        for (_, context) in contexts {
            var ids = [String]()

            if percent < context.strategy.threshold {
                continue
            }

            ids.append("Memory Alert")

            context.update(ids)
        }
    }
    
    override func notify(_ context: WDStrategyContext, _ ids: [String]) {
        for id in ids {
            WDNotificationCenter.shared.notify(title: "\(id)", body: "Memory usage above \(context.strategy.threshold)% over \(context.strategy.duration)s")
        }
    }
    
}
