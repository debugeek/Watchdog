//
//  WDStrategyManager.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/5.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import Combine

class WDStrategyManager {
    
    static let shared = WDStrategyManager()

    let strategiesSubject = PassthroughSubject<[WDStrategy], Never>()
    private(set) var strategies = [WDStrategy]() {
        didSet {
            strategiesSubject.send(strategies)
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(strategies) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "strategies")
    }
    
    func reload() {
        guard let data = UserDefaults.standard.object(forKey: "strategies") as? Data,
              let strategies = try? JSONDecoder().decode([WDStrategy].self, from: data) else {
            return
        }
        self.strategies = strategies
    }
    
    func add(_ strategy: WDStrategy) {
        if strategies.contains(strategy) {
            return
        }
        strategies.append(strategy)
        save()
    }
    
    func delete(_ strategy: WDStrategy) {
        guard let index = strategies.firstIndex(of: strategy) else {
            return
        }
        strategies.remove(at: index)
        save()
    }
    
    func update(_ strategy: WDStrategy) {
        guard let index = strategies.firstIndex(of: strategy) else {
            return
        }
        strategies[index].update(strategy)
        save()
    }
    
}

