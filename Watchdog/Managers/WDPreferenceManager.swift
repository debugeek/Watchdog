//
//  WDPreferenceManager.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/14.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import Combine

class WDPreferenceManager {
    
    static let shared = WDPreferenceManager()
    
    let refreshIntervalSubject = PassthroughSubject<TimeInterval, Never>()
    
    var launchAtLogin: Bool {
        get { UserDefaults.standard.object(forKey: "LoginAtLaunch") as? Bool ?? false }
        set { UserDefaults.standard.setValue(newValue, forKey: "LoginAtLaunch")}
    }
    
    var refreshInterval: TimeInterval {
        get { UserDefaults.standard.object(forKey: "RefreshInterval") as? TimeInterval ?? 5 }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "RefreshInterval")
            refreshIntervalSubject.send(refreshInterval)
        }
    }
}
