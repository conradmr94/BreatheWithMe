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
    @Published var alarmVolume: Float = 0.8 // Default to 80%
    
    private let bellPlayer = BellPlayer()
    private var bellPlayTimer: Timer?
    private var alarmPlayer: AVAudioPlayer?
    private let snoozeDuration: TimeInterval = 5 * 60 // 5 minutes
    private var currentAlarmSound: NoiseGenerator.NoiseType = .birds
    
    // Background keepalive for locked screen alarm support
    private var keepalivePlayer: AVAudioPlayer?
    private var alarmCheckTimer: Timer?
    private var scheduledAlarmDate: Date?
    
    // UserDefaults key for persisting volume
    private let alarmVolumeKey = "alarmVolume"
    
    private init() {
        // Load saved volume
        if let savedVolume = UserDefaults.standard.object(forKey: alarmVolumeKey) as? Float {
            alarmVolume = savedVolume
        }
        registerNotificationCategories()
        requestNotificationPermission()
        setupBackgroundKeepalive()
        
        // Restore alarm check timer if there's a scheduled alarm
        if let alarm = SleepAlarmStore.shared.load(), alarm.isEnabled {
            startAlarmMonitoring(for: alarm.date)
        }
    }
    
    func setAlarmVolume(_ volume: Float) {
        alarmVolume = max(0.0, min(1.0, volume)) // Clamp between 0 and 1
        UserDefaults.standard.set(alarmVolume, forKey: alarmVolumeKey)
        alarmPlayer?.volume = alarmVolume // Update current player if active
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
        
        // Use custom alarm sound in notification
        let selectedSound = NoiseGenerator.NoiseType(rawValue: alarm.sound) ?? .birds
        if let fileName = selectedSound.bundleFileName {
            // UNNotificationSound requires the file to be in the app bundle
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: fileName))
            print("📢 AlarmManager: Notification will use custom sound: \(fileName)")
        } else {
            content.sound = .default
            print("⚠️ AlarmManager: Falling back to default notification sound")
        }
        
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
        configure(alarmSound: selectedSound)
        
        // Start background keepalive and monitoring for locked screen support
        startAlarmMonitoring(for: fireDate)
    }
    
    // Cancel alarm
    func cancel(alarm: SleepAlarm) {
        cancel(identifier: alarm.id.uuidString)
        stopAlarmPlayback()
        stopAlarmMonitoring() // Stop background keepalive
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
        
        // Stop keepalive audio if it's running
        keepalivePlayer?.stop()
        
        // Configure audio session for alarm playback (override any existing session)
        do {
            // Use .playback category to override silent mode
            // Volume is controlled by alarmVolume property (adjustable in settings)
            let audioSession = AVAudioSession.sharedInstance()
            
            // Check system volume and warn if too low
            let systemVolume = audioSession.outputVolume
            if systemVolume < 0.3 {
                print("⚠️ AlarmManager: System media volume is low (\(Int(systemVolume * 100))%). User should increase device volume for louder alarm.")
            }
            
            // Use .playback with no options to ensure maximum loudness
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            
            print("✅ AlarmManager: Audio session configured successfully (overrides silent mode)")
            print("   - Category: \(audioSession.category.rawValue)")
            print("   - Mode: \(audioSession.mode.rawValue)")
            print("   - System Volume: \(Int(systemVolume * 100))%")
            print("   - App Alarm Volume: \(Int(alarmVolume * 100))%")
            print("   - Effective Volume: ~\(Int(systemVolume * alarmVolume * 100))%")
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
        stopAlarmMonitoring() // Stop background keepalive
        
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
        schedule(alarm: alarm) // This will restart monitoring with the new time
        print("✅ AlarmManager: Alarm snoozed until \(newAlarmTime)")
    }
    
    // Play alarm sound (for when app is in foreground - legacy support)
    func playAlarmSound() {
        startAlarm()
    }
    
    // Play alarm sound preview without triggering alarm UI
    func playPreview() {
        print("🎵 AlarmManager: Starting preview playback...")
        
        // Configure audio session for preview
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            print("✅ AlarmManager: Audio session configured for preview")
        } catch {
            print("❌ AlarmManager: Failed to setup audio session for preview: \(error)")
        }
        
        // Stop any existing preview playback
        stopPreview()
        
        // Play the preview
        if playAlarm(using: currentAlarmSound) {
            print("✅ AlarmManager: Preview started with \(currentAlarmSound.description) at \(Int(alarmVolume * 100))%")
        } else {
            print("⚠️ AlarmManager: Could not play preview")
        }
    }
    
    // Stop preview playback without affecting alarm state
    func stopPreview() {
        guard !isAlarmActive else {
            // Don't stop if actual alarm is active
            return
        }
        alarmPlayer?.stop()
        alarmPlayer = nil
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("⚠️ AlarmManager: Unable to deactivate audio session after preview: \(error)")
        }
    }
    
    // Check if alarm time has been reached
    func checkAlarm(identifier: String = "sleepAlarm", completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let hasAlarm = requests.contains { $0.identifier == identifier } || 
                          requests.contains { $0.identifier == "sleepAlarmSnooze" }
            completion(hasAlarm)
        }
    }
    
    // MARK: - Background Keepalive for Locked Screen Alarms
    
    /// Sets up background audio session for alarm keepalive
    private func setupBackgroundKeepalive() {
        // Create silent audio player to keep background audio session alive
        // This allows the alarm to play even when the screen is locked
        guard let url = Bundle.main.url(forResource: "ocean", withExtension: "mp3") else {
            print("⚠️ AlarmManager: Could not find keepalive audio file")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop infinitely
            player.volume = 0.0 // Silent
            player.prepareToPlay()
            keepalivePlayer = player
            print("✅ AlarmManager: Keepalive player prepared")
        } catch {
            print("❌ AlarmManager: Failed to setup keepalive player: \(error)")
        }
    }
    
    /// Starts background audio keepalive and alarm monitoring
    private func startAlarmMonitoring(for date: Date) {
        scheduledAlarmDate = date
        
        // Configure audio session for background
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true, options: [])
            print("✅ AlarmManager: Background audio session activated for alarm monitoring")
        } catch {
            print("❌ AlarmManager: Failed to activate background audio session: \(error)")
        }
        
        // Start silent keepalive audio
        keepalivePlayer?.play()
        print("🔇 AlarmManager: Silent keepalive audio started")
        
        // Start timer to check for alarm time (checks every 5 seconds)
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForAlarmTime()
        }
        RunLoop.main.add(alarmCheckTimer!, forMode: .common)
        print("⏰ AlarmManager: Alarm monitoring started for \(date)")
    }
    
    /// Stops background audio keepalive and monitoring
    private func stopAlarmMonitoring() {
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = nil
        keepalivePlayer?.stop()
        scheduledAlarmDate = nil
        print("🔇 AlarmManager: Alarm monitoring stopped")
    }
    
    /// Checks if the scheduled alarm time has been reached
    @objc private func checkForAlarmTime() {
        guard let alarmDate = scheduledAlarmDate else {
            stopAlarmMonitoring()
            return
        }
        
        let now = Date()
        let timeUntilAlarm = alarmDate.timeIntervalSince(now)
        
        // Trigger alarm if we're within 5 seconds of the alarm time or past it
        if timeUntilAlarm <= 5.0 && timeUntilAlarm >= -60.0 {
            print("⏰ AlarmManager: Alarm time reached! Triggering alarm...")
            stopAlarmMonitoring() // Stop keepalive before starting real alarm
            
            // Trigger the alarm
            DispatchQueue.main.async { [weak self] in
                self?.startAlarm()
            }
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
            player.volume = alarmVolume
            player.prepareToPlay()
            player.play()
            alarmPlayer = player
            print("🎶 AlarmManager: Playing \(sound.description) alarm sound at volume \(Int(alarmVolume * 100))%")
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

