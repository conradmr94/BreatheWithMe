//
//  NotificationDelegate.swift
//  BreatheWithMe
//
//  Handles notification events to trigger alarms when app is in background
//

import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Check if this is an alarm notification
        if notification.request.content.categoryIdentifier == "ALARM" {
            // Trigger alarm sound even when app is in foreground
            AlarmManager.shared.startAlarm()
            // Show notification banner and play sound
            completionHandler([.banner, .sound, .badge])
        } else {
            // For other notifications, use default presentation
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    // Handle notification when user taps on it (app in background)
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is an alarm notification
        if response.notification.request.content.categoryIdentifier == "ALARM" {
            // Trigger alarm sound when user interacts with notification
            AlarmManager.shared.startAlarm()
        }
        
        completionHandler()
    }
}

