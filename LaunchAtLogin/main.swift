//
//  main.swift
//  LaunchAtLogin
//
//  Created by Xiao Jin on 2021/8/14.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import Cocoa

func main() {
    let bundleId = Bundle.main.bundleIdentifier!.replacingOccurrences(of: ".LaunchAtLogin", with: "")
    
    if NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).count > 0 {
        exit(0)
    }
    
    let pathComponents = (Bundle.main.bundlePath as NSString).pathComponents
    let mainPath = NSString.path(withComponents: Array(pathComponents[0...(pathComponents.count - 5)]))
    NSWorkspace.shared.launchApplication(mainPath)
    
    exit(0)
}

main()
