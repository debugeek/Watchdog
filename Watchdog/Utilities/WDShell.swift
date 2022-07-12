//
//  WDShell.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation

class WDShell {

    class func run(path: String, arguments: [String]) -> Bool {
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0;
    }

    class func shell(path: String, arguments: [String]) -> String? {
        let task = Process()
        task.launchPath = path
        task.arguments = arguments

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: String.Encoding.utf8), output.count > 0 {
            let lastIndex = output.index(before: output.endIndex)
            return String(output[output.startIndex..<lastIndex])
        }

        return nil
    }

    class func chmod() {
        let directory = Bundle.main.bundlePath + "/Contents/Resources"

        let wdctl = directory.appending("/wdctl")
        if WDShell.shell(path: "/bin/bash", arguments: ["-c", "ls -la \(wdctl) | awk '{print $3,$4}'"]) == "root admin" {
            return
        }

        let shell = "sudo /bin/bash \(directory)/chmod.sh"

        NSAppleScript(source: "do shell script \"" + shell + "\" with administrator privileges")?.executeAndReturnError(nil)
    }

}

func wdctl(_ arguments: [String]) -> String? {
    guard let wdctl = Bundle(for: WDShell.self).resourceURL?.appendingPathComponent("wdctl").path else {
        return nil
    }
    return WDShell.shell(path: wdctl, arguments: arguments)
}
