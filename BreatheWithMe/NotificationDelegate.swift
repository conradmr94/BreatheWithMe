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
        if notification.request.content.categoryIdentifier == AlarmManager.Constants.categoryID {
            print("🔔 NotificationDelegate: Alarm notification received (app in foreground)")
            // Trigger continuous alarm playback when app is in foreground
            AlarmManager.shared.startAlarm()
            // Show notification banner with sound and badge
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound, .badge, .list])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        } else {
            // For other notifications, use default presentation
            if #available(iOS 14.0, *) {
                completionHandler([.banner, .sound, .badge, .list])
            } else {
                completionHandler([.alert, .sound, .badge])
            }
        }
    }
    
    // Handle notification when user taps on it (app in background or lock screen)
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let category = response.notification.request.content.categoryIdentifier
        
        if category == AlarmManager.Constants.categoryID {
            print("🔔 NotificationDelegate: User interacted with alarm notification (action: \(response.actionIdentifier))")
            
            switch response.actionIdentifier {
            case AlarmManager.Constants.snoozeActionID:
                print("💤 NotificationDelegate: Snooze action tapped")
                AlarmManager.shared.snoozeAlarm()
                
            case AlarmManager.Constants.stopActionID:
                print("🛑 NotificationDelegate: Stop action tapped")
                if var alarm = SleepAlarmStore.shared.load(), alarm.id.uuidString == identifier {
                    alarm.isEnabled = false
                    SleepAlarmStore.shared.save(alarm)
                    AlarmManager.shared.cancel(alarm: alarm)
                }
                AlarmManager.shared.stopAlarm()
                
            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification itself (not an action button)
                print("👆 NotificationDelegate: Notification body tapped - opening app and starting alarm")
                AlarmManager.shared.startAlarm()
                
            case UNNotificationDismissActionIdentifier:
                // User dismissed the notification
                print("❌ NotificationDelegate: Notification dismissed")
                // Don't stop the alarm - it should keep playing
                
            default:
                // Any other action - start the alarm
                print("👆 NotificationDelegate: Unknown action - starting continuous alarm")
                AlarmManager.shared.startAlarm()
            }
        }
        
        completionHandler()
    }
}

