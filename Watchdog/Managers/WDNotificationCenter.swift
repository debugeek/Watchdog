//
//  WDNotificationCenter.swift
//  Watchdog
//
//  Created by Xiao Jin on 2021/8/4.
//  Copyright © 2021 debugeek. All rights reserved.
//

import Foundation
import UserNotifications

class WDNotificationCenter: NSObject {
    
    static let shared = WDNotificationCenter()
    
    private let center = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        center.delegate = self
    }
    
    func requestPermission(completion: @escaping ((Bool) -> ())) {
        center.requestAuthorization(options: .alert) { (result, _) in
            completion(result)
        }
    }
    
    func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger);
        center.add(request)
    }
    
}

extension WDNotificationCenter: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler( [.banner])
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

}
