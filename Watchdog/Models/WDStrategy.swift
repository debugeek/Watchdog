//
//  WDStrategy.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

struct WDStrategy: Codable {
    
    let id: String
    
    enum `Type`: String, Codable {
        case CPU
        case Memory
        case Temperature
    }
    var type: `Type`
    
    var enabled: Bool = false
    
    var threshold: Double
    
    var duration: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case enabled
        case threshold
        case duration
    }
    
    init(_ id: String, _ type: `Type`, _ threshold: Double, _ duration: TimeInterval) {
        self.id = id
        self.type = type
        self.threshold = threshold
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(`Type`.self, forKey: .type)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.threshold = try container.decode(Double.self, forKey: .threshold)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(threshold, forKey: .threshold)
        try container.encode(duration, forKey: .duration)
    }
    
    mutating func update(_ strategy: WDStrategy) {
        self.type = strategy.type
        self.enabled = strategy.enabled
        self.threshold = strategy.threshold
        self.duration = strategy.duration
    }
    
}

