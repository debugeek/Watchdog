//
//  WDMemoryMonitor.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/16.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

class WDMemoryMonitor: WDMonitor {
    
    override func process(_ snapshot: WDSnapshot) {
        guard let used = snapshot.memUsed, let free = snapshot.memFree else { return }
        
        let percent = used/(used + free)*100.0
        
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
