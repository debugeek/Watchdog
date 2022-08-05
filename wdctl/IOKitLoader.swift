//
//  IOKitLoader.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/14.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import IOKit

class IOKitLoader {
    
    typealias IOHIDEventSystemClientCreate_ = @convention(c) (_ allocator: CFAllocator?) -> IOHIDEventSystemClient
    typealias IOHIDEventSystemClientSetMatching_ = @convention(c) (_ client: IOHIDEventSystemClient?, _ matches: CFDictionary?) -> Void
    typealias IOHIDServiceClientCopyEvent_ = @convention(c) (_ client: IOHIDServiceClient, Int64, Int32, Int64) -> Any
    typealias IOHIDEventGetFloatValue_ = @convention(c) (_ event: Any, _ field: UInt32) -> Double
    
    private lazy var handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW);
    private lazy var IOHIDEventSystemClientCreate = unsafeBitCast(dlsym(handle, "IOHIDEventSystemClientCreate"), to: IOHIDEventSystemClientCreate_.self);
    private lazy var IOHIDEventSystemClientSetMatching = unsafeBitCast(dlsym(handle, "IOHIDEventSystemClientSetMatching"), to: IOHIDEventSystemClientSetMatching_.self);
    private lazy var IOHIDServiceClientCopyEvent = unsafeBitCast(dlsym(handle, "IOHIDServiceClientCopyEvent"), to: IOHIDServiceClientCopyEvent_.self);
    private lazy var IOHIDEventGetFloatValue = unsafeBitCast(dlsym(handle, "IOHIDEventGetFloatValue"), to: IOHIDEventGetFloatValue_.self);
    
    static let shared = IOKitLoader()
    
    deinit {
        dlclose(handle)
    }
    
    private func IOHIDGetClients(page: Int, usage: Int) -> [IOHIDServiceClient]? {
        let match = [kIOHIDPrimaryUsagePageKey: page, kIOHIDPrimaryUsageKey: usage] as CFDictionary
        let client: IOHIDEventSystemClient = IOHIDEventSystemClientCreate(nil)
        IOHIDEventSystemClientSetMatching(client, match)
        return IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient]
    }
    
}

extension IOKitLoader {
    
    func getTemperatureValues() -> [String: Double]? {
        var values = [String: Double]()
        
        // kHIDPage_AppleVendor = 0xff00
        // kHIDUsage_AppleVendor_TemperatureSensor = 0x0005
        IOHIDGetClients(page: 0xff00, usage: 0x0005)?
            .forEach({ client in
                guard let name = IOHIDServiceClientCopyProperty(client, "Product" as CFString) as? String else {
                    return
                }

                // kIOHIDEventTypeTemperature = 15
                let event = IOHIDServiceClientCopyEvent(client, 15, 0, 0)
                let temperature = IOHIDEventGetFloatValue(event, 15 << 16)
                values[name] = temperature
            })
        
        return values
    }
    
}
