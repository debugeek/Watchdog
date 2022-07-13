//
//  WDMonitor.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import Cocoa

class WDStrategyContext {
    let strategy: WDStrategy
    
    var records = [String: TimeInterval]()
    
    init(strategy: WDStrategy) {
        self.strategy = strategy
    }
    
    func update(_ ids: [String]) {
        for (id, _) in records.filter({ !ids.contains($0.key) }) {
            records.removeValue(forKey: id)
        }
        
        for id in ids.filter({ records[$0] == nil }) {
            records[id] = machTime()
        }
    }
    
    func validate() -> [String] {
        let now = machTime()
        return records.filter({ now - $1 > strategy.duration }).map { $0.key }
    }
    
    func reset(_ ids: [String]) {
        for id in ids {
            records[id] = nil
        }
    }
    
}

protocol WDMonitorProtocol {
    func process(_ snapshot: WDSnapshot)
    func notify(_ context: WDStrategyContext, _ ids: [String])
}

class WDMonitor: WDMonitorProtocol {
    
    private(set) var contexts = [String: WDStrategyContext]()
    
    func reload(_ strategies: [WDStrategy]?) {
        contexts.removeAll()
        
        strategies?.forEach({ strategy in
            let context = WDStrategyContext(strategy: strategy)
            contexts[strategy.id] = context
        })
    }
    
    func refresh(_ snapshot: WDSnapshot?) {
        guard let snapshot = snapshot, contexts.count > 0 else { return }
        
        process(snapshot)
        
        for (_, context) in contexts {
            if !context.strategy.enabled {
                continue
            }
            
            let ids = context.validate()
            if ids.count == 0 {
                continue
            }
            
            notify(context, ids)
            
            context.reset(ids)
        }
    }
    
    func process(_ snapshot: WDSnapshot) {
        
    }
    
    func notify(_ context: WDStrategyContext, _ ids: [String]) {
        
    }
    
}
