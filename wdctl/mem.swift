//
//  mem.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/17.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import Shared

extension metrics {
    
    func collectMemUsage() -> WDMemUsage? {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS, let total = totalMem() else {
            return nil
        }
        
        let active = Double(stats.active_count) * Double(vm_page_size)
        let speculative = Double(stats.speculative_count) * Double(vm_page_size)
        let inactive = Double(stats.inactive_count) * Double(vm_page_size)
        let wired = Double(stats.wire_count) * Double(vm_page_size)
        let compressed = Double(stats.compressor_page_count) * Double(vm_page_size)
        let purgeable = Double(stats.purgeable_count) * Double(vm_page_size)
        let external = Double(stats.external_page_count) * Double(vm_page_size)
        
        let used = active + inactive + speculative + wired + compressed - purgeable - external
        let free = total - used
        
        return WDMemUsage(used: used, free: free)
    }

    func totalMem() -> Double? {
        var stats = host_basic_info()
        var count = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        let ret: kern_return_t = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &count)
            }
        }
        
        guard ret == KERN_SUCCESS else {
            return nil
        }
        
        return Double(stats.max_mem)
    }
    
}
