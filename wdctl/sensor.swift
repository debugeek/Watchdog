//
//  sensor.swift
//  wdctl
//
//  Created by Xiao Jin on 2021/8/7.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import ArgumentParser
import Darwin

enum `Type`: String, Codable, ExpressibleByArgument {
    case temperature
}

extension snapshot {
    
    func sensor(_ type: `Type`) -> [Any]? {
        guard let values = getSensorValues(0xff00, 0x0005) as? [String: Double] else {
            return nil
        }
        
        var results = [[String: String]]()
        
        for (name, value) in values {
            guard name.hasPrefix("eACC") || name.hasPrefix("pACC") || name.hasPrefix("GPU") || name.hasPrefix("ANE") else {
                continue
            }
            
            guard value > 0 else {
                continue
            }
            
            let result = ["name": name, "temperature": "\(value)"]
            results.append(result)
        }
        
        return results
    }
    
}
