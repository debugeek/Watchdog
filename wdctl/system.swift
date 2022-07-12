//
//  system.swift
//  wdctl
//
//  Created by Xiao Jin on 2021/8/16.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

extension snapshot {
    
    func summary() -> Any? {
        var params = [String: Any]()
        
        if let usage = memoryUsage() {
            params["mem_total"] = usage.0
            params["mem_used"] = usage.1
            params["mem_free"] = usage.2
        }
        
        if let usage = CPUUsage() {
            params["cpu_user"] = usage.0
            params["cpu_system"] = usage.1
            params["cpu_idle"] = usage.2
        }
        
        return params
    }
    
    func memoryUsage() -> (Double, Double, Double)? {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS, let total = memoryTotal() else { return nil }
        
        let active = Double(stats.active_count) * Double(vm_page_size)
        let speculative = Double(stats.speculative_count) * Double(vm_page_size)
        let inactive = Double(stats.inactive_count) * Double(vm_page_size)
        let wired = Double(stats.wire_count) * Double(vm_page_size)
        let compressed = Double(stats.compressor_page_count) * Double(vm_page_size)
        let purgeable = Double(stats.purgeable_count) * Double(vm_page_size)
        let external = Double(stats.external_page_count) * Double(vm_page_size)
        
        let used = active + inactive + speculative + wired + compressed - purgeable - external
        let free = total - used
        
        return (total, used, free)
    }
    
    func CPUUsage() -> (Double, Double, Double)? {
        var count: natural_t = 0
        var info: processor_info_array_t!
        var infoCount: mach_msg_type_number_t = 0
        
        let result: kern_return_t = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &info, &infoCount)
        guard result == KERN_SUCCESS else { return nil }
            
        var usages = [Double]()
        
        for i in 0..<Int32(count) {
            var use: Int32 = 0
            var total: Int32 = 0
            
            use = info[Int(CPU_STATE_MAX*i + CPU_STATE_USER)] + info[Int(CPU_STATE_MAX*i + CPU_STATE_SYSTEM)] + info[Int(CPU_STATE_MAX*i + CPU_STATE_NICE)]
            total = use + info[Int(CPU_STATE_MAX * i + CPU_STATE_IDLE)]
            
            if total != 0 {
                usages.append(Double(use)/Double(total))
            }
        }
        
        var i = 0
        var a = 0
        
        var usagePerCore = [Double]()
        while i < Int(usages.count/2) {
            a = i*2
            if usages.indices.contains(a) && usages.indices.contains(a + 1) {
                usagePerCore.append((Double(usages[a]) + Double(usages[a + 1]))/2)
            }
            i += 1
        }
        
        guard let loadInfo = CPULoadInfo() else { return nil }
        
        let user = Double(loadInfo.cpu_ticks.0)
        let sys  = Double(loadInfo.cpu_ticks.1)
        let idle = Double(loadInfo.cpu_ticks.2)
        let nice = Double(loadInfo.cpu_ticks.3)
        let total = sys + user + nice + idle
        
        return (user/total, sys/total, idle/total)
    }
    
    func CPULoadInfo() -> host_cpu_load_info? {
        let count = MemoryLayout<host_cpu_load_info>.stride/MemoryLayout<integer_t>.stride
        var size = mach_msg_type_number_t(count)
        var info = host_cpu_load_info()
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: count) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        if result != KERN_SUCCESS {
            return nil
        }
        
        return info
    }

    func memoryTotal() -> Double? {
        var stats = host_basic_info()
        var count = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        let ret: kern_return_t = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &count)
            }
        }
        
        guard ret == KERN_SUCCESS else { return nil }
        
        return Double(stats.max_mem)
    }
    
}
