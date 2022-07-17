//
//  process.swift
//  wdctl
//
//  Created by Xiao Jin on 2022/7/17.
//  Copyright © 2022 debugeek. All rights reserved.
//

import Foundation
import Shared

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
