//
//  cpu.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/17.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import Shared

extension metrics {
    
    func collectCPUUsage() -> WDCPUUsage? {
        var count: natural_t = 0
        var info: processor_info_array_t!
        var infoCount: mach_msg_type_number_t = 0
        
        let result: kern_return_t = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &count, &info, &infoCount)
        guard result == KERN_SUCCESS else {
            return nil
        }
            
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
        
        return WDCPUUsage(system: sys/total, user: user/total, idle: idle/total)
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
    
}
