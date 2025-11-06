//
//  AlarmManager.swift
//  BreatheWithMe
//
//  Manages alarm notifications for sleep tracking

import Foundation
import UserNotifications
import AVFoundation
import AudioToolbox
import Combine

class AlarmManager: ObservableObject {
    static let shared = AlarmManager()
    
    @Published var isAlarmActive = false
    @Published var snoozeTime: Date?
    
    private let bellPlayer = BellPlayer()
    private var alarmTimer: Timer?
    private var bellPlayTimer: Timer?
    private let snoozeDuration: TimeInterval = 5 * 60 // 5 minutes
    
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
        // Cancel both regular and snooze alarms
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier, "sleepAlarmSnooze"])
        stopAlarm()
        print("✅ AlarmManager: Alarm cancelled")
    }
    
    // Start alarm (plays bell sound repeatedly)
    func startAlarm() {
        guard !isAlarmActive else { 
            print("⚠️ AlarmManager: Alarm already active, ignoring start request")
            return 
        }
        
        print("🔔 AlarmManager: Starting alarm...")
        isAlarmActive = true
        snoozeTime = nil
        
        // Configure audio session for alarm playback (override any existing session)
        do {
            // Use .playback category with no mixing to ensure alarm plays even if other audio is playing
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            print("✅ AlarmManager: Audio session configured successfully")
        } catch {
            print("❌ AlarmManager: Failed to setup audio session: \(error)")
        }
        
        // Play bell immediately on main thread
        DispatchQueue.main.async { [weak self] in
            print("🔔 AlarmManager: Playing bell sound...")
            self?.bellPlayer.playBell()
        }
        
        // Schedule repeated bell playback every 3.5 seconds (bell duration)
        bellPlayTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                print("🔔 AlarmManager: Repeating bell sound...")
                self?.bellPlayer.playBell()
            }
        }
        
        print("✅ AlarmManager: Alarm started successfully")
    }
    
    // Stop alarm
    func stopAlarm() {
        guard isAlarmActive else { return }
        
        isAlarmActive = false
        snoozeTime = nil
        bellPlayTimer?.invalidate()
        bellPlayTimer = nil
        
        print("✅ AlarmManager: Alarm stopped")
    }
    
    // Snooze alarm (stop for now, reschedule for later)
    func snoozeAlarm() {
        guard isAlarmActive else { return }
        
        let newAlarmTime = Date().addingTimeInterval(snoozeDuration)
        snoozeTime = newAlarmTime
        
        // Stop current alarm
        stopAlarm()
        
        // Reschedule for snooze time
        scheduleAlarm(at: newAlarmTime, identifier: "sleepAlarmSnooze")
        
        print("✅ AlarmManager: Alarm snoozed until \(newAlarmTime)")
    }
    
    // Play alarm sound (for when app is in foreground - legacy support)
    func playAlarmSound() {
        startAlarm()
    }
    
    // Check if alarm time has been reached
    func checkAlarm(identifier: String = "sleepAlarm", completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let hasAlarm = requests.contains { $0.identifier == identifier } || 
                          requests.contains { $0.identifier == "sleepAlarmSnooze" }
            completion(hasAlarm)
        }
    }
}

