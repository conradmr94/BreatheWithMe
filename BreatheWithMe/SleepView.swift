//
//  SleepView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.


import SwiftUI
import HealthKit
import UserNotifications

// MARK: - Data Model
struct SleepStats: Codable {
    var sleepSessionsCompleted: Int = 0
    var totalSleepTimeSeconds: Int = 0
    
    var totalSleepTimeFormatted: String {
        let hours = totalSleepTimeSeconds / 3600
        let minutes = (totalSleepTimeSeconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "\(totalSleepTimeSeconds)s"
        }
    }
    
    var averageSleepTimeFormatted: String {
        guard sleepSessionsCompleted > 0 else { return "—" }
        let avgSeconds = totalSleepTimeSeconds / sleepSessionsCompleted
        let hours = avgSeconds / 3600
        let minutes = (avgSeconds % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "\(avgSeconds)s"
        }
    }
}

struct SleepView: View {
    @State private var showProfile: Bool = false
    @State private var isRunning = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    @State private var showNoiseSettings = false
    @State private var sessionStartTime: Date?
    
    // Alarm functionality
    @State private var alarm: SleepAlarm?
    @State private var alarmTimePickerValue: Date = Date()
    @State private var selectedAlarmSound: NoiseGenerator.NoiseType = .birds
    @State private var showAlarmSettings = false
    @StateObject private var alarmManager = AlarmManager.shared
    @AppStorage("focusLockUntilTimestamp") private var focusLockUntilTimestamp: Double = 0
    @State private var isPreviewingAlarm = false
    @State private var alarmPreviewWorkItem: DispatchWorkItem?

    init() {
        let storedAlarm = SleepAlarmStore.shared.load()
        _alarm = State(initialValue: storedAlarm)
        let defaultDate = Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
        _alarmTimePickerValue = State(initialValue: storedAlarm?.date ?? defaultDate)
        let sound = storedAlarm.flatMap { NoiseGenerator.NoiseType(rawValue: $0.sound) } ?? .birds
        _selectedAlarmSound = State(initialValue: sound)
        AlarmManager.shared.configure(alarmSound: sound)
    }
    
    // Statistics tracking
    @AppStorage("sleepStats") private var sleepStatsData: Data = Data()
    @StateObject private var userStatsManager = UserStatsManager()
    
    private var sleepStats: SleepStats {
        get {
            if let decoded = try? JSONDecoder().decode(SleepStats.self, from: sleepStatsData) {
                return decoded
            }
            return SleepStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                sleepStatsData = encoded
            }
        }
    }

    // HealthKit VM (optional enhancement)
    @StateObject private var vm = SleepViewModel()
    // Noise Generator for ambient sounds
    @StateObject private var noiseGenerator = NoiseGenerator()
    // Session Manager for enhanced tracking
    @StateObject private var sessionManager = SessionManager.shared
    private static let focusLockTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    private static let focusLockRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    private var backgroundView: some View {
        ZStack {
            // Deep night gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Twinkling stars
            if !isRunning {
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.7)))
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height * 0.6)
                        )
                }
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
                // Top section
                VStack(spacing: 12) {
                    if !isRunning {
                        Text("Sleep")
                            .font(.system(size: 34, weight: .light, design: .default))
                            .foregroundColor(.white.opacity(0.9))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        Text("Drift away peacefully")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(.white.opacity(0.6))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 120)
                .padding(.top, 50)
                
                Spacer()
                
                // Main sleep circle
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.3 - Double(index) * 0.1),
                                        Color(red: 0.5, green: 0.4, blue: 0.7).opacity(0.2 - Double(index) * 0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 250 + CGFloat(index) * 40, height: 250 + CGFloat(index) * 40)
                            .opacity(isRunning ? 0.6 : 0.3)
                            .scaleEffect(isRunning ? pulseScale + Double(index) * 0.05 : 1.0)
                    }
                    
                    // Moon circle
                    Button(action: toggleTimer) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.85, green: 0.87, blue: 0.95),
                                            Color(red: 0.75, green: 0.77, blue: 0.85)
                                        ]),
                                        center: .topLeading,
                                        startRadius: 0,
                                        endRadius: 150
                                    )
                                )
                                .frame(width: 220, height: 220)
                                .shadow(color: Color(red: 0.6, green: 0.65, blue: 0.9).opacity(0.5), radius: 40, x: 0, y: 10)
                                .scaleEffect(isRunning ? pulseScale : 1.0)
                            
                            // Moon craters
                            Circle().fill(Color(red: 0.7, green: 0.72, blue: 0.8).opacity(0.3)).frame(width: 30, height: 30).offset(x: -40, y: -20)
                            Circle().fill(Color(red: 0.7, green: 0.72, blue: 0.8).opacity(0.2)).frame(width: 20, height: 20).offset(x: 30, y: 15)
                            Circle().fill(Color(red: 0.7, green: 0.72, blue: 0.8).opacity(0.25)).frame(width: 25, height: 25).offset(x: 10, y: -35)
                            
                            // Content
                            VStack(spacing: 12) {
                                if isRunning {
                                    Text(formatTime(elapsedSeconds))
                                        .font(.system(size: 52, weight: .thin, design: .default))
                                        .foregroundColor(Color(red: 0.3, green: 0.35, blue: 0.5))
                                        .monospacedDigit()
                                } else {
                                    VStack(spacing: 10) {
                                        Image(systemName: "moon.stars.fill")
                                            .font(.system(size: 42, weight: .thin))
                                            .foregroundColor(Color(red: 0.4, green: 0.45, blue: 0.6))
                                        Text("START")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(Color(red: 0.4, green: 0.45, blue: 0.6))
                                            .tracking(2)
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: 450)
                .onAppear {
                    if isRunning { startPulseAnimation() }
                }

                Spacer()
                
                // Bottom section
                VStack(spacing: 24) {
                    // Alarm settings (when not running)
                    if !isRunning {
                        let accent = Color(red: 0.4, green: 0.5, blue: 0.8)
                        VStack(alignment: .center, spacing: 10) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    alarmTimePickerValue = alarmFireDate
                                    showAlarmSettings = true
                                }) {
                                    HStack(spacing: 8) {
                                        Text("Alarm")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(accent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(accent.opacity(0.22))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                Spacer()
                            }

                            if isAlarmEnabled {
                                VStack(alignment: .center, spacing: 4) {
                                    Text("Next alarm: \(alarmDisplayTime)")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Sound: \(selectedAlarmSound.description)")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                            }
                        }
                    }
                    
                    // Noise settings (always visible)
                    VStack(spacing: 12) {
                        // Open noise settings modal
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showNoiseSettings = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: noiseGenerator.isEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                                    .font(.system(size: 16))
                                Text("Sleep Sounds")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                            }
                            .foregroundColor(noiseGenerator.isEnabled ? 
                                           Color(red: 0.4, green: 0.5, blue: 0.8) :
                                           Color.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(noiseGenerator.isEnabled ? 
                                          Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.25) :
                                          Color.white.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.opacity)
                    
                    if isRunning {
                        VStack(spacing: 12) {
                            Text("Relax and let go")
                                .font(.system(size: 16, weight: .regular, design: .default))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Button(action: stopTimer) {
                                Text("Stop")
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 155)
                .padding(.bottom, 60)
        }
    }
    
    private var isAlarmEnabled: Bool {
        alarm?.isEnabled == true
    }
    
    private var alarmFireDate: Date {
        alarm?.date ?? alarmTimePickerValue
    }
    
    private var alarmDisplayTime: String {
        formatAlarmTime(alarmFireDate)
    }
    private var alarmTimeBinding: Binding<Date> {
        Binding(
            get: { alarmTimePickerValue },
            set: { newValue in updateAlarmDate(to: newValue) }
        )
    }
    private var alarmSoundBinding: Binding<NoiseGenerator.NoiseType> {
        Binding(
            get: { selectedAlarmSound },
            set: { newValue in
                if selectedAlarmSound != newValue {
                    selectedAlarmSound = newValue
                    persistAlarmSound(newValue)
                }
            }
        )
    }
    private var focusLockActive: Bool {
        focusLockUntilTimestamp > Date().timeIntervalSince1970
    }
    private var focusLockEndDate: Date {
        Date(timeIntervalSince1970: focusLockUntilTimestamp)
    }
    private var focusLockStatusText: String {
        guard focusLockActive else {
            return "Locks the app until your alarm goes off."
        }
        let timeText = SleepView.focusLockTimeFormatter.string(from: focusLockEndDate)
        let relative = SleepView.focusLockRelativeFormatter.localizedString(for: focusLockEndDate, relativeTo: Date())
        return "Locked until \(timeText) (\(relative))."
    }
    private var focusLockToggleBinding: Binding<Bool> {
        Binding<Bool>(
            get: { focusLockActive },
            set: { newValue in
                if newValue {
                    enableFocusLock()
                } else {
                    disableFocusLock()
                }
            }
        )
    }
    
    private var alarmEnabledBinding: Binding<Bool> {
        Binding<Bool>(
            get: { isAlarmEnabled },
            set: { newValue in
                // Only toggle if the value is actually changing
                if newValue != isAlarmEnabled {
                    toggleAlarm()
                }
            }
        )
    }

    private func toggleAlarm() {
        if var existing = alarm {
            existing.isEnabled.toggle()
            existing.sound = selectedAlarmSound.rawValue
            if existing.isEnabled {
                AlarmManager.shared.requestNotificationPermission()
                existing.date = normalizedFireDate(from: alarmTimePickerValue)
                alarmTimePickerValue = existing.date
                SleepAlarmStore.shared.save(existing)
                alarm = existing
                AlarmManager.shared.schedule(alarm: existing)
                if focusLockActive {
                    enableFocusLock(haptic: false)
                }
            } else {
                SleepAlarmStore.shared.save(existing)
                alarm = existing
                AlarmManager.shared.cancel(alarm: existing)
                if focusLockActive {
                    disableFocusLock()
                }
            }
        } else {
            AlarmManager.shared.requestNotificationPermission()
            let newAlarm = SleepAlarm(date: normalizedFireDate(from: alarmTimePickerValue), isEnabled: true, label: "Wake Up", snoozeMinutes: 10, sound: selectedAlarmSound.rawValue)
            alarmTimePickerValue = newAlarm.date
            SleepAlarmStore.shared.save(newAlarm)
            alarm = newAlarm
            AlarmManager.shared.schedule(alarm: newAlarm)
        }
    }

    private func updateAlarmDate(to newValue: Date) {
        alarmTimePickerValue = newValue
        let adjusted = normalizedFireDate(from: newValue)
        if var existing = alarm {
            existing.date = adjusted
            alarmTimePickerValue = adjusted
            SleepAlarmStore.shared.save(existing)
            alarm = existing
            if existing.isEnabled {
                AlarmManager.shared.requestNotificationPermission()
                AlarmManager.shared.schedule(alarm: existing)
                if focusLockActive {
                    enableFocusLock(haptic: false)
                }
            }
        } else {
            let newAlarm = SleepAlarm(date: adjusted, isEnabled: false, label: "Wake Up", snoozeMinutes: 10, sound: selectedAlarmSound.rawValue)
            SleepAlarmStore.shared.save(newAlarm)
            alarm = newAlarm
        }
    }

    private func persistAlarmSound(_ newSound: NoiseGenerator.NoiseType) {
        stopAlarmPreview()
        if var existing = alarm {
            existing.sound = newSound.rawValue
            SleepAlarmStore.shared.save(existing)
            alarm = existing
            if existing.isEnabled {
                AlarmManager.shared.requestNotificationPermission()
                AlarmManager.shared.schedule(alarm: existing)
            }
        } else {
            let newAlarm = SleepAlarm(date: normalizedFireDate(from: alarmTimePickerValue), isEnabled: false, label: "Wake Up", snoozeMinutes: 10, sound: newSound.rawValue)
            SleepAlarmStore.shared.save(newAlarm)
            alarm = newAlarm
        }
        alarmManager.configure(alarmSound: newSound)
    }

    private func normalizedFireDate(from date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: date)
        let now = Date()
        components.year = calendar.component(.year, from: now)
        components.month = calendar.component(.month, from: now)
        components.day = calendar.component(.day, from: now)
        var candidate = calendar.date(from: components) ?? date
        if candidate <= now {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }
        return candidate
    }
    
    private func enableFocusLock(haptic: Bool = true) {
        let target = normalizedFireDate(from: alarmTimePickerValue)
        let minimumLock = Date().addingTimeInterval(60)
        let lockDate = target > minimumLock ? target : minimumLock
        focusLockUntilTimestamp = lockDate.timeIntervalSince1970
        if haptic {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func disableFocusLock() {
        focusLockUntilTimestamp = 0
    }
    
    private func previewAlarmSound() {
        if isPreviewingAlarm {
            stopAlarmPreview()
            return
        }
        alarmManager.configure(alarmSound: selectedAlarmSound)
        alarmManager.playAlarmSound()
        isPreviewingAlarm = true
        let workItem = DispatchWorkItem {
            stopAlarmPreview()
        }
        alarmPreviewWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: workItem)
    }
    
    private func stopAlarmPreview() {
        alarmPreviewWorkItem?.cancel()
        alarmPreviewWorkItem = nil
        if isPreviewingAlarm {
            alarmManager.stopAlarm()
            isPreviewingAlarm = false
        }
    }
    
    @ViewBuilder
    private var infoMessageOverlay: some View {
        if noiseGenerator.showInfoMessage {
            VStack {
                Spacer()
                Text(noiseGenerator.infoMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
    
    @ViewBuilder
    private var modalsOverlay: some View {
        if showNoiseSettings {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNoiseSettings = false
                        }
                    }
                SleepNoiseOptionsModal(
                    isPresented: $showNoiseSettings,
                    noiseGenerator: noiseGenerator,
                    isRunning: isRunning
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(2)
        }
        
        // Alarm Settings overlay
        if showAlarmSettings {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAlarmSettings = false
                            stopAlarmPreview()
                        }
                    }
                AlarmSettingsSheet(
                    isAlarmEnabled: alarmEnabledBinding,
                    alarmDate: alarmTimeBinding,
                    selectedSound: alarmSoundBinding,
                    soundOptions: NoiseGenerator.NoiseType.alarmEligibleCases,
                    focusLockBinding: focusLockToggleBinding,
                    focusLockDescription: focusLockStatusText,
                    isPreviewing: isPreviewingAlarm,
                    previewAction: {
                        if isPreviewingAlarm {
                            stopAlarmPreview()
                        } else {
                            previewAlarmSound()
                        }
                    },
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAlarmSettings = false
                            stopAlarmPreview()
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(3)
        }
        
        // Alarm UI overlay (when alarm is active)
        if alarmManager.isAlarmActive {
                AlarmActiveOverlay(
                    alarmManager: alarmManager,
                    onDismiss: {
                        alarmManager.stopAlarm()
                        if isRunning {
                            stopTimer()
                        }
                    },
                    onSnooze: {
                        alarmManager.snoozeAlarm()
                    }
                )
            .zIndex(4)
            .transition(.opacity)
        }
    }
    
    private var baseView: some View {
        ZStack {
            backgroundView
            mainContentView
        }
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(.dark)
        .swipeDownToOpenProfile {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showProfile = true }
        }
        .topSlideCover(isPresented: $showProfile) {
            ProfileView(
                onDismiss: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showProfile = false }
                },
                isPresented: $showProfile
            )
            .preferredColorScheme(.light)
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view.toolbar(showProfile ? .hidden : .visible, for: .tabBar)
            } else {
                view
            }
        }
    }
    
    var body: some View {
        baseView
        .overlay(infoMessageOverlay)
        .overlay(modalsOverlay)
            .onAppear {
                vm.onAppear()
                alarmManager.configure(alarmSound: selectedAlarmSound)
            }
            .onChange(of: selectedAlarmSound) { newValue in
                persistAlarmSound(newValue)
            }
            .onDisappear {
                stopAlarmPreview()
            }
    }
    
    // --- Existing timer logic with session tracking ---
    func toggleTimer() { isRunning ? stopTimer() : startTimer() }
    func startTimer() {
        stopAlarmPreview()
        isRunning = true
        elapsedSeconds = 0
        sessionStartTime = Date()
        startPulseAnimation()
        alarmManager.configure(alarmSound: selectedAlarmSound)
        
        // Start noise if enabled
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        
        // Check for alarm every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            elapsedSeconds += 1
        }
    }
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Stop alarm if active
        if alarmManager.isAlarmActive {
            alarmManager.stopAlarm()
        }
        
        // Track sleep session if it was at least 60 seconds (1 minute)
        if let startTime = sessionStartTime, elapsedSeconds >= 60 {
            let endTime = Date()
            let sessionDuration = Int(endTime.timeIntervalSince(startTime))
            
            // Update local sleep stats
            var stats = sleepStats
            stats.totalSleepTimeSeconds += sessionDuration
            stats.sleepSessionsCompleted += 1
            
            // Save to storage
            if let encoded = try? JSONEncoder().encode(stats) {
                sleepStatsData = encoded
            }
            
            // Record in UserStatsManager for streak tracking
            userStatsManager.recordSession(activityType: .sleep, durationSeconds: sessionDuration)
            
            // Calculate basic metadata
            let goalDuration = 8 * 3600 // 8 hours default
            let historicalBedtimes = sessionManager.sessions(ofType: .sleep, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
                .map { $0.start }
            let isRegular = SleepScoreCalculator.isBedtimeRegular(
                currentBedtime: startTime,
                historicalBedtimes: historicalBedtimes,
                toleranceMinutes: 30
            )
            
            // Track content usage if noise was enabled
            var contentId: String? = nil
            var contentDuration: Int? = nil
            if noiseGenerator.isEnabled {
                contentId = noiseGenerator.selectedNoiseType.description
                contentDuration = sessionDuration
            }
            
            // Try to get wakeups and WASO from HealthKit (async)
            Task { @MainActor in
                var wakeups = 0
                var wasoSeconds = 0
                
                // Fetch HealthKit data for this sleep session
                do {
                    let hk = HealthKitManager.shared
                    let (hkWakeups, hkWASO) = try await hk.analyzeSleepEvents(from: startTime, to: endTime)
                    wakeups = hkWakeups
                    wasoSeconds = hkWASO
                } catch {
                    // If HealthKit fails, use defaults (0)
                    print("⚠️ Sleep: Could not fetch HealthKit sleep events: \(error)")
                }
                
                // Create enhanced session with metadata
                var meta = EnhancedSession.SessionMetadata()
                meta.wakeups = wakeups
                meta.wasoSeconds = wasoSeconds
                meta.bedtimeRegularity = isRegular
                meta.snoreMinutes = nil // TODO: Integrate audio event detector
                meta.contentId = contentId
                meta.contentDuration = contentDuration
                
                // Calculate sleep score with HealthKit data (or defaults if not available)
                meta.sleepScore = SleepScoreCalculator.calculateScore(
                    durationSeconds: sessionDuration,
                    goalDurationSeconds: goalDuration,
                    bedtimeRegularity: isRegular,
                    wakeups: wakeups,
                    wasoSeconds: wasoSeconds
                )
                
                let enhancedSession = EnhancedSession(
                    type: .sleep,
                    start: startTime,
                    end: endTime,
                    meta: meta
                )
                
                // Save enhanced session
                sessionManager.saveSession(enhancedSession)
            }
        }
        
        elapsedSeconds = 0
        sessionStartTime = nil
        pulseScale = 1.0
        
        // Stop noise
        if noiseGenerator.isEnabled {
            noiseGenerator.stopNoise()
        }
    }
    func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    func formatAlarmTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


// MARK: - Sound Category Model
struct SoundCategory {
    let name: String
    let icon: String
    let sounds: [NoiseGenerator.NoiseType]
    
    static let allCategories: [SoundCategory] = [
        SoundCategory(name: "Nature", icon: "leaf", sounds: [.rain, .ocean, .wind, .thunder, .forest, .birds, .night, .cafe, .city, .fire]),
        SoundCategory(name: "Noise", icon: "waveform", sounds: [.white, .pink, .brown, .blue, .green]),
        SoundCategory(name: "Frequency", icon: "slider.horizontal.3", sounds: []),
        SoundCategory(name: "Melody", icon: "music.note", sounds: [])
    ]
}

// MARK: - Modal for Sleep Sounds
struct SleepNoiseOptionsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var noiseGenerator: NoiseGenerator
    let isRunning: Bool
    
    @State private var expandedCategories: Set<String> = []

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Sounds")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SoundCategory.allCategories, id: \.name) { category in
                        CategorySection(
                            category: category,
                            isExpanded: expandedCategories.contains(category.name),
                            selectedNoiseType: noiseGenerator.selectedNoiseType,
                            columns: columns,
                            onToggle: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedCategories.contains(category.name) {
                                        expandedCategories.remove(category.name)
                                    } else {
                                        expandedCategories.insert(category.name)
                                    }
                                }
                            },
                            onSoundSelected: { noiseType in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    noiseGenerator.setNoiseType(noiseType)
                                }
                                if [.white, .pink, .brown, .blue, .green].contains(noiseType) {
                                    noiseGenerator.showInfoForNoiseType(noiseType)
                                }
                            }
                        )
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: 260)
            
            VStack(spacing: 12) {
                Text("Enable sleep sounds?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 12) {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            noiseGenerator.isEnabled = false
                        }
                        if isRunning { noiseGenerator.stopNoise() }
                        withAnimation(.easeInOut(duration: 0.2)) { 
                            isPresented = false 
                        } 
                    }) {
                        Text("No")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            noiseGenerator.isEnabled = true
                        }
                        if isRunning { noiseGenerator.startNoise() }
                        withAnimation(.easeInOut(duration: 0.2)) { 
                            isPresented = false 
                        } 
                    }) {
                        Text("Yes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.4, green: 0.5, blue: 0.8))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Category Section Component
struct CategorySection: View {
    let category: SoundCategory
    let isExpanded: Bool
    let selectedNoiseType: NoiseGenerator.NoiseType
    let columns: [GridItem]
    let onToggle: () -> Void
    let onSoundSelected: (NoiseGenerator.NoiseType) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Category header
            Button(action: onToggle) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                    Text(category.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.95, green: 0.96, blue: 0.98))
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded sounds grid
            if isExpanded {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(category.sounds, id: \.self) { noiseType in
                        Button(action: {
                            onSoundSelected(noiseType)
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: noiseType.icon)
                                    .font(.system(size: 20))
                                Text(noiseType.description)
                                    .font(.system(size: 12, weight: .medium))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(selectedNoiseType == noiseType ? .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedNoiseType == noiseType ? Color(red: 0.4, green: 0.5, blue: 0.8) : Color.white.opacity(0.95))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Alarm Time Picker Modal
struct AlarmTimePickerModal: View {
    @Binding var isPresented: Bool
    @Binding var alarmTime: Date
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Alarm Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            DatePicker(
                "Alarm Time",
                selection: $alarmTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 200)
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.6))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    // Save the alarm time
                    onSave()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }) {
                    Text("Set")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.4, green: 0.5, blue: 0.8))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Alarm Sound Picker Modal
struct AlarmSoundPickerModal: View {
    @Binding var isPresented: Bool
    @Binding var selectedSound: NoiseGenerator.NoiseType
    
    private let options = NoiseGenerator.NoiseType.alarmEligibleCases
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose Alarm Sound")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { sound in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedSound = sound
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: sound.icon)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sound.description)
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Nature sound")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                            }
                            Spacer()
                            if sound == selectedSound {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(sound == selectedSound ? Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.18) : Color.white.opacity(0.95))
                        )
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            }) {
                Text("Close")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(red: 0.4, green: 0.5, blue: 0.8))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 12)
        )
    }
}

// MARK: - Alarm Active Overlay
struct AlarmActiveOverlay: View {
    @ObservedObject var alarmManager: AlarmManager
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Alarm icon with pulse animation
                ZStack {
                    // Pulsing circles
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.3 - Double(index) * 0.1))
                            .frame(width: 200 + CGFloat(index) * 40, height: 200 + CGFloat(index) * 40)
                            .scaleEffect(pulseScale + Double(index) * 0.05)
                    }
                    
                    // Main alarm icon
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                        .scaleEffect(pulseScale)
                }
                .frame(height: 300)
                
                // Wake up text
                VStack(spacing: 12) {
                    Text("Wake Up")
                        .font(.system(size: 36, weight: .light, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Time to start your day")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    // Snooze button
                    Button(action: {
                        onSnooze()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 24))
                            Text("Snooze")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Dismiss button
                    Button(action: {
                        onDismiss()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                            Text("Dismiss")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.4, green: 0.5, blue: 0.8))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
    }
}

private struct AlarmSettingsSheet: View {
    @Binding var isAlarmEnabled: Bool
    @Binding var alarmDate: Date
    @Binding var selectedSound: NoiseGenerator.NoiseType
    let soundOptions: [NoiseGenerator.NoiseType]
    let focusLockBinding: Binding<Bool>
    let focusLockDescription: String
    let isPreviewing: Bool
    let previewAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with title and close button
            HStack {
                Text("Alarm Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.black.opacity(0.25))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 24) {
                // Alarm Toggle
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Alarm")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    Toggle(isOn: $isAlarmEnabled) {
                        Text("Enable alarm")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.5, blue: 0.8)))
                }
                
                // Wake Time
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                        Text("Wake Time")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    DatePicker(
                        "",
                        selection: $alarmDate,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .disabled(!isAlarmEnabled)
                    .opacity(isAlarmEnabled ? 1.0 : 0.5)
                    .frame(height: 140)
                }
                
                // Alarm Sound
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                        Text("Alarm Sound")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(soundOptions, id: \.self) { sound in
                            HStack {
                                Image(systemName: sound.icon)
                                Text(sound.description)
                            }
                            .tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!isAlarmEnabled)
                    .opacity(isAlarmEnabled ? 1.0 : 0.5)
                    .padding(.top, 4)
                    
                    Button(action: previewAction) {
                        HStack {
                            Image(systemName: isPreviewing ? "stop.circle.fill" : "play.circle")
                            Text(isPreviewing ? "Stop Preview" : "Preview Sound")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(isAlarmEnabled ? Color(red: 0.4, green: 0.5, blue: 0.8) : Color(red: 0.4, green: 0.5, blue: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isAlarmEnabled ? Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.15) : Color.white.opacity(0.6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isAlarmEnabled)
                }
                
                // Focus Lock
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lock")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                        Text("Focus Lock")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    Toggle(isOn: focusLockBinding) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Block distracting apps")
                                .font(.system(size: 15, weight: .medium))
                            Text(focusLockDescription)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.5, blue: 0.8)))
                    .disabled(!isAlarmEnabled)
                    .opacity(isAlarmEnabled ? 1.0 : 0.5)
                }
            }
            .padding(.top, 4)
            
            // Done button
            Button(action: {
                onDismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.4, green: 0.5, blue: 0.8))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

#Preview {
    SleepView()
}
