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
        return IOKitLoader.shared.getTemperatureVallues()?
            .filter { $1 > 0 }
            .map { WDSensor(name: $0, value: $1) }
    }
    
}
