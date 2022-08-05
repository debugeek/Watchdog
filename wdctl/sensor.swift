//
//  sensor.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/17.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import Shared

extension metrics {
    
    func collectSensors() -> [WDSensor]? {
#if arch(arm64)
        return IOKitLoader.shared.getTemperatureValues()?
            .filter { $1 > 0 }
            .map { WDSensor(name: $0, value: $1) }
#else
        return IOKitSMC.shared.getTemperatureValues()?
            .filter { $1 > 0 }
            .map { WDSensor(name: $0, value: $1) }
#endif
    }
    
}

