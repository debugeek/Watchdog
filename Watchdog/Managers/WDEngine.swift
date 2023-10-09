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
import Shared

class WDEngine {
    
    static var shared = WDEngine()
    
    private let monitors: [WDMonitor] = [WDCPUMonitor(), WDSensorMonitor(), WDMemoryMonitor()]
    
    private var timer: DGTimer?
    
    let metricsSubject = CurrentValueSubject<WDMetrics?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    func launch() {
        WDStrategyManager.shared.strategiesSubject
            .sink { [weak self] (strategies) in
                self?.monitors.forEach({ monitor in
                    if monitor is WDCPUMonitor {
                        monitor.reload(strategies.filter { $0.type == .CPU })
                    } else if monitor is WDSensorMonitor {
                        monitor.reload(strategies.filter { $0.type == .Temperature })
                    } else if monitor is WDMemoryMonitor {
                        monitor.reload(strategies.filter { $0.type == .Memory })
                    }
                })
            }
            .store(in: &cancellables)
        
        WDPreferenceManager.shared.refreshIntervalSubject
            .filter { $0 > 0 }
            .sink { [weak self] (refreshInterval) in
                self?.timer?.reschedule(timeInterval: refreshInterval)
            }
            .store(in: &cancellables)
        
        WDStrategyManager.shared.reload()
            
        timer = DGTimer.scheduledTimer(timeInterval: WDPreferenceManager.shared.refreshInterval, repeats: true, queue: .main, block: { [weak self] timer in
            self?.collectMetrics()
        })
        
        collectMetrics()
    }
    
    private func collectMetrics() {
        guard let json = wdctl(["metrics"]),
              let data = json.data(using: .utf8),
              let metrics = WDMetrics.decode(data) else {
            return
        }

        metricsSubject.send(metrics)

        for monitor in monitors {
            monitor.refresh(metrics)
        }
    }
    
}
