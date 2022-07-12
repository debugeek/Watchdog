//
//  WDEngine.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import Combine
import DGFoundation

class WDEngine {
    
    static var shared = WDEngine()
    
    private let monitors: [WDMonitor] = [WDCPUMonitor(), WDSensorMonitor(), WDMemoryMonitor()]
    
    private var timer: DGTimer?
    
    private var strategiesSubscriber: AnyCancellable?
    private var refreshIntervalSubscriber: AnyCancellable?
    
    let snapshotSubject = CurrentValueSubject<WDSnapshot?, Never>(nil)
    
    func launch() {
        strategiesSubscriber = WDStrategyManager.shared.strategiesSubject
            .sink { [weak self] (strategies) in
                self?.monitors.forEach({ monitor in
                    if monitor is WDCPUMonitor {
                        monitor.reload(strategies?.filter { $0.type == .CPU })
                    } else if monitor is WDSensorMonitor {
                        monitor.reload(strategies?.filter { $0.type == .Temperature })
                    } else if monitor is WDMemoryMonitor {
                        monitor.reload(strategies?.filter { $0.type == .Memory })
                    }
                })
        }
        
        refreshIntervalSubscriber = WDPreferenceManager.shared.refreshIntervalSubject
            .filter { $0 > 0 }
            .sink { [weak self] (refreshInterval) in
                self?.timer?.reschedule(repeatingInterval: refreshInterval)
        }
        
        WDStrategyManager.shared.reload()
            
        timer = DGTimer.scheduledTimer(timeInterval: WDPreferenceManager.shared.refreshInterval, repeats: true, queue: .main, block: { [weak self] timer in
            self?.snapshot()
        })
        
        snapshot()
    }
    
    private func snapshot() {
        guard let json = wdctl(["snapshot"]),
              let data = json.data(using: .utf8),
              let params = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        
        var snapshot = WDSnapshot()
        
        if let summary = params["summary"] as? [String: Any] {
            if let memUsed = summary["mem_used"] as? Double {
                snapshot.memUsed = memUsed
            }
            if let memFree = summary["mem_free"] as? Double {
                snapshot.memFree = memFree
            }
        }
        if let ps = params["ps"] as? [[String: Any]] {
            snapshot.processes = ps.compactMap {
                guard let name = $0["name"] as? String,
                      let pid = $0["pid"] as? Int32,
                      let cpu = $0["cpu"] as? Double,
                      let mem = $0["mem"] as? Int64 else {
                    return nil
                }
                return WDProcess(name: name, pid: pid, cpu: cpu, mem: mem)
            }
        }
        if let temperature = params["temperature"] as? [[String: String]] {
            snapshot.temperatures = temperature.compactMap {
                guard let name = $0["name"], let valueStr = $0["temperature"], let value = Double(valueStr) else {
                    return nil
                }
                return WDTemperature(name: name, value: value)
            }
        }
        
        snapshotSubject.send(snapshot)
        
        for monitor in monitors {
            monitor.refresh(snapshot)
        }
    }
    
}
