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
    @AppStorage("alarmEnabled") private var alarmEnabled = false
    @AppStorage("alarmTime") private var alarmTimeData: Data = Data()
    @State private var showAlarmPicker = false
    @State private var alarmTimePickerValue: Date = Date()
    @StateObject private var alarmManager = AlarmManager.shared
    @State private var alarmFired = false
    
    private var alarmTime: Date {
        get {
            if let decoded = try? JSONDecoder().decode(Date.self, from: alarmTimeData) {
                return decoded
            }
            // Default to 8 hours from now
            return Calendar.current.date(byAdding: .hour, value: 8, to: Date()) ?? Date()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                alarmTimeData = encoded
            }
        }
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
                        VStack(spacing: 12) {
                            // Alarm toggle and time picker
                            HStack(spacing: 16) {
                                // Alarm toggle
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        alarmEnabled.toggle()
                                        if !alarmEnabled {
                                            alarmManager.cancelAlarm()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: alarmEnabled ? "alarm.fill" : "alarm")
                                            .font(.system(size: 16))
                                        Text(alarmEnabled ? formatAlarmTime(alarmTime) : "Set Alarm")
                                            .font(.system(size: 15, weight: .medium, design: .default))
                                    }
                                    .foregroundColor(alarmEnabled ? 
                                                   Color(red: 0.4, green: 0.5, blue: 0.8) :
                                                   Color.white.opacity(0.6))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(alarmEnabled ? 
                                                  Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.25) :
                                                  Color.white.opacity(0.1))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Time picker button
                                if alarmEnabled {
                                    Button(action: {
                                        alarmTimePickerValue = alarmTime
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showAlarmPicker = true
                                        }
                                    }) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
                                            .padding(10)
                                            .background(
                                                Circle()
                                                    .fill(Color(red: 0.4, green: 0.5, blue: 0.8).opacity(0.25))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .transition(.opacity)
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
        
        // Alarm time picker modal
        if showAlarmPicker {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAlarmPicker = false
                        }
                    }
                AlarmTimePickerModal(
                    isPresented: $showAlarmPicker,
                    alarmTime: $alarmTimePickerValue,
                    onSave: {
                        if let encoded = try? JSONEncoder().encode(alarmTimePickerValue) {
                            alarmTimeData = encoded
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
                    alarmFired = false  // Reset so alarm can fire again if needed
                    if isRunning {
                        stopTimer()
                    }
                },
                onSnooze: {
                    alarmManager.snoozeAlarm()
                    alarmFired = false  // Reset for snooze alarm
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
            }
    }
    
    // --- Existing timer logic with session tracking ---
    func toggleTimer() { isRunning ? stopTimer() : startTimer() }
    func startTimer() {
        isRunning = true
        elapsedSeconds = 0
        sessionStartTime = Date()
        alarmFired = false
        startPulseAnimation()
        
        // Schedule alarm if enabled
        if alarmEnabled {
            // Ensure alarm time is in the future
            var targetAlarmTime = alarmTime
            let now = Date()
            if targetAlarmTime <= now {
                // If alarm time is in the past, set it for tomorrow
                targetAlarmTime = Calendar.current.date(byAdding: .day, value: 1, to: targetAlarmTime) ?? targetAlarmTime
            }
            alarmManager.scheduleAlarm(at: targetAlarmTime)
            // Update stored alarm time directly
            if let encoded = try? JSONEncoder().encode(targetAlarmTime) {
                alarmTimeData = encoded
            }
            print("✅ Sleep: Alarm scheduled for \(targetAlarmTime)")
        }
        
        // Start noise if enabled
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        
        // Check for alarm every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
            elapsedSeconds += 1
            
            // Check if alarm time has been reached
            // Only fire if alarm is enabled, not already active, and time matches
            if alarmEnabled && !alarmManager.isAlarmActive {
                let now = Date()
                let calendar = Calendar.current
                let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
                let alarmComponents = calendar.dateComponents([.hour, .minute], from: alarmTime)
                
                // Check if current time matches alarm time (within same minute)
                if nowComponents.hour == alarmComponents.hour && 
                   nowComponents.minute == alarmComponents.minute {
                    // Fire alarm if we haven't fired yet, or if alarm was stopped (allowing re-fire)
                    if !alarmFired {
                        print("🔔 Sleep: Alarm time reached! Current: \(now), Alarm: \(alarmTime)")
                        alarmFired = true
                        DispatchQueue.main.async {
                            self.alarmManager.startAlarm()
                        }
                    }
                } else {
                    // Reset alarmFired when we move to a different minute
                    // This allows alarm to fire again for the next alarm time
                    if alarmFired {
                        alarmFired = false
                    }
                }
            }
            
            // Check for snooze alarm
            if let snoozeTime = alarmManager.snoozeTime, !alarmManager.isAlarmActive {
                let now = Date()
                if now >= snoozeTime {
                    print("🔔 Sleep: Snooze alarm time reached! Current: \(now), Snooze: \(snoozeTime)")
                    DispatchQueue.main.async {
                        self.alarmManager.startAlarm()
                    }
                }
            }
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
        
        // Reset alarmFired flag so alarm can fire again if needed
        alarmFired = false
        
        // Cancel alarm if still pending
        if alarmEnabled {
            alarmManager.cancelAlarm()
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


// MARK: - Modal for Sleep Sounds
struct SleepNoiseOptionsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var noiseGenerator: NoiseGenerator
    let isRunning: Bool

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
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(NoiseGenerator.NoiseType.allCases, id: \.self) { noiseType in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                noiseGenerator.setNoiseType(noiseType)
                            }
                            if [.white, .pink, .brown, .blue, .green].contains(noiseType) {
                                noiseGenerator.showInfoForNoiseType(noiseType)
                            }
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
                            .foregroundColor(noiseGenerator.selectedNoiseType == noiseType ? .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(noiseGenerator.selectedNoiseType == noiseType ? Color(red: 0.4, green: 0.5, blue: 0.8) : Color.white.opacity(0.95))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
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

#Preview {
    SleepView()
}
