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
        let identifier = response.notification.request.identifier
        let category = response.notification.request.content.categoryIdentifier
        if category == AlarmManager.Constants.categoryID {
            switch response.actionIdentifier {
            case AlarmManager.Constants.snoozeActionID:
                if var alarm = SleepAlarmStore.shared.load(), alarm.id.uuidString == identifier {
                    let newDate = Date().addingTimeInterval(TimeInterval(alarm.snoozeMinutes * 60))
                    alarm.date = newDate
                    alarm.isEnabled = true
                    SleepAlarmStore.shared.save(alarm)
                    AlarmManager.shared.schedule(alarm: alarm)
                }
                AlarmManager.shared.stopAlarm()
            case AlarmManager.Constants.stopActionID:
                if var alarm = SleepAlarmStore.shared.load(), alarm.id.uuidString == identifier {
                    alarm.isEnabled = false
                    SleepAlarmStore.shared.save(alarm)
                    AlarmManager.shared.cancel(alarm: alarm)
                }
                AlarmManager.shared.stopAlarm()
            default:
                AlarmManager.shared.startAlarm()
            }
        }
        
        completionHandler()
    }
}

