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
    enum Constants {
        static let categoryID = "ALARM_CATEGORY"
        static let snoozeActionID = "ALARM_SNOOZE"
        static let stopActionID = "ALARM_STOP"
    }
    
    @Published var isAlarmActive = false
    @Published var snoozeTime: Date?
    
    private let bellPlayer = BellPlayer()
    private var bellPlayTimer: Timer?
    private var alarmPlayer: AVAudioPlayer?
    private let snoozeDuration: TimeInterval = 5 * 60 // 5 minutes
    private var currentAlarmSound: NoiseGenerator.NoiseType = .birds
    
    private init() {
        registerNotificationCategories()
        requestNotificationPermission()
    }
    
    func configure(alarmSound: NoiseGenerator.NoiseType) {
        if alarmSound.isAmbientSound {
            currentAlarmSound = alarmSound
        } else {
            currentAlarmSound = .birds
        }
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
    
    func registerNotificationCategories() {
        let snooze = UNNotificationAction(
            identifier: Constants.snoozeActionID,
            title: "Snooze 10 min",
            options: []
        )
        let stop = UNNotificationAction(
            identifier: Constants.stopActionID,
            title: "Stop",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: Constants.categoryID,
            actions: [snooze, stop],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // Schedule alarm notification
    func schedule(alarm: SleepAlarm) {
        guard alarm.isEnabled else {
            cancel(alarm: alarm)
            return
        }
        var fireDate = alarm.date
        if fireDate <= Date() {
            fireDate = Calendar.current.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate.addingTimeInterval(24 * 60 * 60)
            var updatedAlarm = alarm
            updatedAlarm.date = fireDate
            SleepAlarmStore.shared.save(updatedAlarm)
        }
        cancel(identifier: alarm.id.uuidString)
        let content = UNMutableNotificationContent()
        content.title = alarm.label ?? "Alarm"
        content.body = "Time to wake up"
        content.sound = .default
        content.categoryIdentifier = Constants.categoryID
        content.userInfo = ["alarmId": alarm.id.uuidString]
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ AlarmManager: Failed to schedule alarm: \(error)")
            } else {
                print("✅ AlarmManager: Alarm scheduled for \(fireDate)")
            }
        }
        let selectedSound = NoiseGenerator.NoiseType(rawValue: alarm.sound) ?? .birds
        configure(alarmSound: selectedSound)
    }
    
    // Cancel alarm
    func cancel(alarm: SleepAlarm) {
        cancel(identifier: alarm.id.uuidString)
        stopAlarmPlayback()
        isAlarmActive = false
        snoozeTime = nil
        print("✅ AlarmManager: Alarm cancelled")
    }
    
    // Start alarm (plays selected nature sound, falling back to bell)
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
            // Use .playback category which plays audio even in silent mode
            // The .playback category automatically plays through speakers and overrides silent mode
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            print("✅ AlarmManager: Audio session configured successfully (will play in silent mode)")
            print("   - Category: \(audioSession.category.rawValue)")
            print("   - Mode: \(audioSession.mode.rawValue)")
            print("   - Is active: \(audioSession.isOtherAudioPlaying)")
        } catch {
            print("❌ AlarmManager: Failed to setup audio session: \(error)")
        }
        
        // Stop any existing playback before starting (without deactivating session)
        stopAlarmPlayback(deactivateSession: false)
        
        if playAlarm(using: currentAlarmSound) {
            print("✅ AlarmManager: Alarm started successfully with \(currentAlarmSound.description) sound")
        } else {
            print("⚠️ AlarmManager: Falling back to bell sound for alarm")
            playFallbackBell()
        }
    }
    
    // Stop alarm
    func stopAlarm() {
        guard isAlarmActive else { return }
        
        isAlarmActive = false
        snoozeTime = nil
        stopAlarmPlayback()
        
        print("✅ AlarmManager: Alarm stopped")
    }
    
    func snoozeAlarm() {
        guard var alarm = SleepAlarmStore.shared.load() else {
            stopAlarm()
            return
        }
        let newAlarmTime = Date().addingTimeInterval(TimeInterval(alarm.snoozeMinutes * 60))
        alarm.date = newAlarmTime
        alarm.isEnabled = true
        SleepAlarmStore.shared.save(alarm)
        snoozeTime = newAlarmTime
        stopAlarm()
        schedule(alarm: alarm)
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

// MARK: - Private helpers

private extension AlarmManager {
    func playAlarm(using sound: NoiseGenerator.NoiseType) -> Bool {
        guard let fileName = sound.bundleFileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("❌ AlarmManager: Missing audio asset for \(sound.rawValue) alarm sound")
            return false
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            alarmPlayer = player
            print("🎶 AlarmManager: Playing \(sound.description) alarm sound")
            return true
        } catch {
            print("❌ AlarmManager: Failed to play alarm sound \(sound.rawValue): \(error)")
            return false
        }
    }
    
    func playFallbackBell() {
        DispatchQueue.main.async { [weak self] in
            print("🔔 AlarmManager: Playing bell sound...")
            self?.bellPlayer.playBell()
        }
        bellPlayTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                print("🔔 AlarmManager: Repeating bell sound...")
                self?.bellPlayer.playBell()
            }
        }
    }
    
    func stopAlarmPlayback(deactivateSession: Bool = true) {
        alarmPlayer?.stop()
        alarmPlayer = nil
        bellPlayTimer?.invalidate()
        bellPlayTimer = nil
        guard deactivateSession else { return }
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("⚠️ AlarmManager: Unable to deactivate audio session: \(error)")
        }
    }

    func cancel(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

