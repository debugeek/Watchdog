//
//  WDSensorMonitor.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/6.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

class WDSensorMonitor: WDMonitor {
    
    override func process(_ snaptshot: WDSnapshot) {
        guard let temperatures = snaptshot.temperatures, temperatures.count > 0 else {
            return
        }
        
        var hash = [String: Double]()
        for temperature in temperatures {
            hash[temperature.name] = temperature.value
        }
        
        for (_, context) in contexts {
            var names = [String]()
            
            for (name, value) in hash {
                if value < context.strategy.threshold {
                    continue
                }
                
                names.append(name)
            }
            
            context.update(names)
        }
    }
    
    override func notify(_ context: WDStrategyContext, _ ids: [String]) {
        for id in ids {
            WDNotificationCenter.shared.notify(title: "\(id)", body: "temperature above \(context.strategy.threshold)°C over \(context.strategy.duration)s")
        }
    }
}





