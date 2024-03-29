//
//  WDPreferenceViewController.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa
import Combine
import ServiceManagement

class WDPreferenceViewController: NSViewController {

    @IBOutlet weak var launchAtLoginSwitch: NSSwitch!
    @IBOutlet weak var refreshIntervalField: NSTextField!

    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        launchAtLoginSwitch.state = WDPreferenceManager.shared.launchAtLogin ? .on : .off
        refreshIntervalField.stringValue = "\(WDPreferenceManager.shared.refreshInterval)"
        
        launchAtLoginSwitch.statePublisher
            .sink(receiveValue: { state in
                let launchAtLogin = state == .on ? true : false
                
                let id = "\(Bundle.main.bundleIdentifier!).LaunchAtLogin" as CFString
                SMLoginItemSetEnabled(id, launchAtLogin)
                
                WDPreferenceManager.shared.launchAtLogin = launchAtLogin
            })
            .store(in: &cancellables)
        
        refreshIntervalField.textDidEndEditingPublisher
            .sink { stringValue in
                guard let refreshInterval = Double(stringValue), refreshInterval > 0 else {
                    return
                }
                WDPreferenceManager.shared.refreshInterval = refreshInterval
            }
            .store(in: &cancellables)
    }
    
}
