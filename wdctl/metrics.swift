//
//  metrics.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/14.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import ArgumentParser
import Shared

struct metrics: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "system info metrics")
    
    func run() throws {
        var metrics = WDMetrics()
        metrics.CPUUsage = collectCPUUsage()
        metrics.memUsage = collectMemUsage()
        metrics.processes = collectProcesses()
        metrics.sensors = collectSensors()
        
        guard let data = metrics.encode(),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        
        print(string)
    }
    
}

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

extension metrics {
    
    func collectProcesses() -> [WDProcess]? {
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-Aceo pcpu,rss,pid,comm", "-r"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        defer {
            outputPipe.fileHandleForReading.closeFile()
            errorPipe.fileHandleForReading.closeFile()
        }
        
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        try? task.run()
        
        task.waitUntilExit()
        
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if errorData.count > 0 {
            return nil
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        if output.count == 0 {
            return nil
        }
        
        var processes = [WDProcess]()
        
        output.enumerateLines { (line, stop) -> Void in
            var str = line.trimmingCharacters(in: .whitespaces)
            guard let pcpuStr = str.search(pattern: "^[0-9,.]+ ", trim: true)?.replacingOccurrences(of: ",", with: "."), let cpu = Double(pcpuStr) else {
                return
            }
            
            guard let rssStr = str.search(pattern: "^[0-9,.]+ ", trim: true)?.replacingOccurrences(of: ",", with: "."), let mem = Int64(rssStr) else {
                return
            }
            
            guard let pidStr = str.search(pattern: "^\\d+", trim: true), let pid = Int32(pidStr) else {
                return
            }
            
            guard str.count > 0 else {
                return
            }
            
            let process = WDProcess(name: str, pid: pid, cpu: cpu, mem: mem*1024)
            processes.append(process)
        }
        
        return processes
    }
    
}

extension metrics {
    
    func collectSensors() -> [WDSensor]? {
        return IOKitLoader.shared.getTemperatureVallues()?
            .filter { $1 > 0 }
            .map { WDSensor(name: $0, value: $1) }
    }
    
}

extension String {
    
    mutating func search(pattern: String, trim: Bool = false) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let stringRange = NSRange(location: 0, length: self.utf16.count)
        var line = self
        
        guard let searchRange = regex.firstMatch(in: self, options: [], range: stringRange) else {
            return nil
        }
        
        let start = self.index(self.startIndex, offsetBy: searchRange.range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: searchRange.range.upperBound)
        let value = String(self[start..<end]).trimmingCharacters(in: .whitespaces)
        
        if trim {
            line = self.replacingOccurrences(of: value, with: "", options: .regularExpression)
            self = line.trimmingCharacters(in: .whitespaces)
        }
        
        return value.trimmingCharacters(in: .whitespaces)
    }
    
}
