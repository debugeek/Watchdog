//
//  WDMetrics.swift
//  Shared
//
//  Created by Xiao Jin on 2022/7/14.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation

public struct WDProcess: Codable {
    public let name: String
    public let pid: Int32
    public let cpu: Double
    public let mem: Int64
    
    public init(name: String, pid: Int32, cpu: Double, mem: Int64) {
        self.name = name
        self.pid = pid
        self.cpu = cpu
        self.mem = mem
    }
}

public struct WDMemUsage: Codable {
    public let used: Double
    public let free: Double
    
    public init(used: Double, free: Double) {
        self.used = used
        self.free = free
    }
}

public struct WDCPUUsage: Codable {
    public let system: Double
    public let user: Double
    public let idle: Double
    
    public init(system: Double, user: Double, idle: Double) {
        self.system = system
        self.user = user
        self.idle = idle
    }
}

public struct WDSensor: Codable {
    public let name: String
    public let value: Double
    
    public init(name: String, value: Double) {
        self.name = name
        self.value = value
    }
}

public struct WDMetrics: Codable {
    public var CPUUsage: WDCPUUsage?
    public var memUsage: WDMemUsage?
    public var processes: [WDProcess]?
    public var sensors: [WDSensor]?
    
    public init() {}
    
    public static func decode(_ data: Data) -> WDMetrics? {
        do {
            return try JSONDecoder().decode(Self.self, from: data)
        } catch _ {
            return nil
        }
    }

    public func encode() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch let e {
            print(e)
            return nil
        }
    }
}
