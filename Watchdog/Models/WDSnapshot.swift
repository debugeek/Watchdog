//
//  WDSnapshot.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/14.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

struct WDSnapshot {
    
    var CPUSystem: Double?
    var CPUUser: Double?
    var CPUIdle: Double?
    
    var memUsed: Double?
    var memFree: Double?
    
    var processes: [WDProcess]?
    
    var temperatures: [WDTemperature]?
    
}
