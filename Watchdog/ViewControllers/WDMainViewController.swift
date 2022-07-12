//
//  WDMainViewController.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa

class WDMainViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabViewItems.forEach { $0.color = NSColor.red }
        
    }
    
}
