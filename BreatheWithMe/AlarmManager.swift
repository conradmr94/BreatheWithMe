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
    
    // Alarm interaction tracking
    var currentAlarmStartTime: Date?
    var currentAlarmSnoozeCount: Int = 0
    
    // UserDefaults key for persisting volume
    private let alarmVolumeKey = "alarmVolume"
    
    private init() {
        // Load saved volume
        if let savedVolume = UserDefaults.standard.object(forKey: alarmVolumeKey) as? Float {
            alarmVolume = savedVolume
        }
        registerNotificationCategories()
        setupBackgroundKeepalive()
        
        // Request permissions on init so we can check status
        // But don't show the prompt yet - that happens when user sets an alarm
        checkNotificationStatus()
        
        // Restore alarm check timer if there's a scheduled alarm
        if let alarm = SleepAlarmStore.shared.load(), alarm.isEnabled {
            startAlarmMonitoring(for: alarm.date)
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Notification authorization status: \(settings.authorizationStatus.rawValue)")
            if settings.authorizationStatus == .denied {
                print("⚠️ Notifications are DENIED - user needs to enable in Settings")
            }
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
        // First check current authorization status
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Current notification authorization: \(settings.authorizationStatus.rawValue)")
            
            switch settings.authorizationStatus {
            case .notDetermined:
                // Request permissions if not yet determined
                print("🔔 Requesting notification permissions...")
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("❌ AlarmManager: Failed to request notification permission: \(error)")
                    } else if granted {
                        print("✅ AlarmManager: Notification permission granted")
                        self.logNotificationSettings()
                    } else {
                        print("⚠️ AlarmManager: Notification permission denied by user")
                        print("   User needs to enable notifications in Settings app")
                    }
                }
                
            case .denied:
                print("❌ AlarmManager: Notifications are DENIED")
                print("   📱 User must go to: Settings > BreatheWithMe > Notifications")
                print("   📱 Then enable 'Allow Notifications'")
                
            case .authorized, .provisional, .ephemeral:
                print("✅ AlarmManager: Notifications already authorized")
                self.logNotificationSettings()
                
            @unknown default:
                print("⚠️ AlarmManager: Unknown authorization status")
            }
        }
    }
    
    private func logNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📋 Notification Settings Details:")
            print("   - Lock Screen: \(settings.lockScreenSetting.rawValue) (0=notSupported, 1=disabled, 2=enabled)")
            print("   - Alert Style: \(settings.alertSetting.rawValue) (0=notSupported, 1=disabled, 2=enabled)")
            print("   - Sound: \(settings.soundSetting.rawValue)")
            if settings.lockScreenSetting == .disabled {
                print("   ⚠️ LOCK SCREEN NOTIFICATIONS ARE DISABLED!")
                print("   📱 Go to: Settings > BreatheWithMe > Notifications > Lock Screen")
            }
            if settings.alertSetting == .disabled {
                print("   ⚠️ ALERT NOTIFICATIONS ARE DISABLED!")
            }
        }
    }
    
    func registerNotificationCategories() {
        let snooze = UNNotificationAction(
            identifier: Constants.snoozeActionID,
            title: "Snooze",
            options: [.foreground]
        )
        let stop = UNNotificationAction(
            identifier: Constants.stopActionID,
            title: "Stop",
            options: [.destructive, .foreground]
        )
        let category = UNNotificationCategory(
            identifier: Constants.categoryID,
            actions: [snooze, stop],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        print("✅ AlarmManager: Notification categories registered with foreground actions")
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
        
        // Get the selected alarm sound for configuration
        let selectedSound = NoiseGenerator.NoiseType(rawValue: alarm.sound) ?? .birds
        
        // Use default notification sound since iOS doesn't support .mp3 files for notifications
        // The actual alarm sound will play through background audio session (see startAlarmMonitoring)
        // iOS only supports .caf, .aiff, .wav, or .m4a for notification sounds, not .mp3
        content.sound = .default
        print("📢 AlarmManager: Using default notification sound (alarm sound will play via background audio)")
        
        // Configure for lock screen display
        content.categoryIdentifier = Constants.categoryID
        content.userInfo = ["alarmId": alarm.id.uuidString, "isAlarm": true]
        
        // Make notification time-sensitive so it breaks through Focus modes and shows prominently
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0 // Highest relevance
        }
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: alarm.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ AlarmManager: Failed to schedule alarm: \(error)")
            } else {
                print("✅ AlarmManager: Alarm scheduled for \(fireDate)")
                
                // Verify notification was added
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    let alarmNotifications = requests.filter { $0.identifier == alarm.id.uuidString }
                    print("📋 AlarmManager: Found \(alarmNotifications.count) pending alarm notification(s)")
                    if let notification = alarmNotifications.first {
                        print("   - ID: \(notification.identifier)")
                        print("   - Title: \(notification.content.title)")
                        print("   - Body: \(notification.content.body)")
                        if let trigger = notification.trigger as? UNCalendarNotificationTrigger {
                            print("   - Trigger: \(trigger.nextTriggerDate() ?? Date())")
                        }
                    }
                }
                
                // Check notification settings
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    print("📱 Notification Settings:")
                    print("   - Authorization: \(settings.authorizationStatus.rawValue)")
                    print("   - Alert: \(settings.alertSetting.rawValue)")
                    print("   - Sound: \(settings.soundSetting.rawValue)")
                    print("   - Badge: \(settings.badgeSetting.rawValue)")
                    print("   - Lock Screen: \(settings.lockScreenSetting.rawValue)")
                    print("   - Notification Center: \(settings.notificationCenterSetting.rawValue)")
                    if #available(iOS 15.0, *) {
                        print("   - Time Sensitive: \(settings.timeSensitiveSetting.rawValue)")
                    }
                }
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
        currentAlarmStartTime = Date() // Track when alarm started
        currentAlarmSnoozeCount = 0 // Reset snooze count
        
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
        currentAlarmSnoozeCount += 1 // Track snooze count
        let newAlarmTime = Date().addingTimeInterval(TimeInterval(alarm.snoozeMinutes * 60))
        alarm.date = newAlarmTime
        alarm.isEnabled = true
        SleepAlarmStore.shared.save(alarm)
        snoozeTime = newAlarmTime
        stopAlarm()
        schedule(alarm: alarm) // This will restart monitoring with the new time
        print("✅ AlarmManager: Alarm snoozed until \(newAlarmTime) (snooze count: \(currentAlarmSnoozeCount))")
    }
    
    func recordAlarmDismissed() -> (snoozes: Int, responseTime: Int) {
        let snoozes = currentAlarmSnoozeCount
        var responseTime = 0
        
        if let startTime = currentAlarmStartTime {
            responseTime = Int(Date().timeIntervalSince(startTime))
        }
        
        // Reset tracking for next alarm
        resetAlarmTracking()
        
        return (snoozes: snoozes, responseTime: responseTime)
    }
    
    func resetAlarmTracking() {
        currentAlarmStartTime = nil
        currentAlarmSnoozeCount = 0
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
    
    // Test function to verify notifications work on lock screen
    func sendTestNotification() {
        print("🧪 Sending test notification...")
        
        let content = UNMutableNotificationContent()
        content.title = "Test Alarm"
        content.body = "This is a test notification to verify lock screen display"
        content.sound = .default
        content.categoryIdentifier = Constants.categoryID
        
        // Make it time-sensitive
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
        }
        
        // Trigger in 5 seconds
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test-alarm", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test notification failed: \(error)")
            } else {
                print("✅ Test notification scheduled - will appear in 5 seconds")
                print("   Lock your phone now to test lock screen display!")
            }
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
        
        // Configure audio session for background playback
        // This is critical for alarm to work when screen is locked
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use .playback category to ensure audio plays even when locked
            // .mixWithOthers is NOT used to ensure we can override silent mode
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true, options: [])
            print("✅ AlarmManager: Background audio session activated for alarm monitoring")
            print("   - Category: \(audioSession.category.rawValue)")
            print("   - Mode: \(audioSession.mode.rawValue)")
        } catch {
            print("❌ AlarmManager: Failed to activate background audio session: \(error)")
        }
        
        // Start silent keepalive audio to maintain background audio session
        keepalivePlayer?.play()
        print("🔇 AlarmManager: Silent keepalive audio started")
        
        // Start timer to check for alarm time (checks every 1 second for more precise timing)
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        
        // Trigger alarm if we're within 1 second of the alarm time or past it
        // More precise timing ensures alarm triggers exactly when notification fires
        if timeUntilAlarm <= 1.0 && timeUntilAlarm >= -60.0 {
            print("⏰ AlarmManager: Alarm time reached! Triggering alarm...")
            stopAlarmMonitoring() // Stop keepalive before starting real alarm
            
            // Trigger the alarm immediately
            // Use main queue to ensure UI updates work, but don't delay audio playback
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

