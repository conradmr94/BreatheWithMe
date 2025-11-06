//
//  AlarmManager.swift
//  BreatheWithMe
//
//  Manages alarm notifications for sleep tracking

import Foundation
import UserNotifications
import AVFoundation
import AudioToolbox

class AlarmManager: ObservableObject {
    static let shared = AlarmManager()
    
    private init() {
        requestNotificationPermission()
    }
    
    // Request notification permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ AlarmManager: Failed to request notification permission: \(error)")
            } else if granted {
                print("✅ AlarmManager: Notification permission granted")
            }
        }
    }
    
    // Schedule alarm notification
    func scheduleAlarm(at date: Date, identifier: String = "sleepAlarm") {
        // Cancel any existing alarm
        cancelAlarm(identifier: identifier)
        
        let content = UNMutableNotificationContent()
        content.title = "Wake Up"
        content.body = "Time to wake up! Your sleep session has ended."
        content.sound = .default
        content.categoryIdentifier = "ALARM"
        content.userInfo = ["alarmId": identifier]
        
        // Schedule notification
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ AlarmManager: Failed to schedule alarm: \(error)")
            } else {
                print("✅ AlarmManager: Alarm scheduled for \(date)")
            }
        }
    }
    
    // Cancel alarm
    func cancelAlarm(identifier: String = "sleepAlarm") {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ AlarmManager: Alarm cancelled")
    }
    
    // Play alarm sound (for when app is in foreground)
    func playAlarmSound() {
        // Use system sound for alarm
        AudioServicesPlaySystemSound(1005) // System sound ID for alarm
    }
    
    // Check if alarm time has been reached
    func checkAlarm(identifier: String = "sleepAlarm", completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let hasAlarm = requests.contains { $0.identifier == identifier }
            completion(hasAlarm)
        }
    }
}

