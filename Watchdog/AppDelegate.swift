//
//  AppDelegate.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/3.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    var windowController: WDMainWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusItem.menu = statusMenu
        statusItem.button?.image = NSImage(systemSymbolName: "binoculars", accessibilityDescription: nil)
        
        WDShell.chmod()
        
        WDEngine.shared.launch()
        
        WDNotificationCenter.shared.requestPermission { (result) in
            print("notification permission:\(result)")
        }
    }
    
    @IBAction func openItemDidSelected(_ sender: NSMenuItem) {
        if windowController == nil {
            windowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "WDMainWindowController") as? WDMainWindowController
        }
        
        guard let windowController = windowController else { return }
        
        windowController.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
        windowController.window?.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func quitItemDidSelected(_ sender: NSMenuItem) {
        NSApp.terminate(nil)
    }
}

