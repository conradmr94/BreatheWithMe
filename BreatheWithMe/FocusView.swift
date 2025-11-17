//
//  FocusView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Data Model
struct FocusStats: Codable {
    var focusSessionsCompleted: Int = 0
    var totalFocusTimeSeconds: Int = 0
    var totalRestTimeSeconds: Int = 0
    var restSessionsCompleted: Int = 0
    var longestFocusSessionSeconds: Int = 0
    var shortBreaksCompleted: Int = 0
    var longBreaksCompleted: Int = 0
    var totalShortBreakTimeSeconds: Int = 0
    var totalLongBreakTimeSeconds: Int = 0
    
    var totalFocusTimeFormatted: String {
        let hours = totalFocusTimeSeconds / 3600
        let minutes = (totalFocusTimeSeconds % 3600) / 60
        let seconds = totalFocusTimeSeconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var totalRestTimeFormatted: String {
        let hours = totalRestTimeSeconds / 3600
        let minutes = (totalRestTimeSeconds % 3600) / 60
        let seconds = totalRestTimeSeconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var averageFocusDuration: Int {
        guard focusSessionsCompleted > 0 else { return 0 }
        return totalFocusTimeSeconds / focusSessionsCompleted
    }
    
    var averageFocusDurationFormatted: String {
        let seconds = averageFocusDuration
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var averageRestDuration: Int {
        guard restSessionsCompleted > 0 else { return 0 }
        return totalRestTimeSeconds / restSessionsCompleted
    }
    
    var averageRestDurationFormatted: String {
        let seconds = averageRestDuration
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var averageShortBreakDuration: Int {
        guard shortBreaksCompleted > 0 else { return 0 }
        return totalShortBreakTimeSeconds / shortBreaksCompleted
    }
    
    var averageShortBreakDurationFormatted: String {
        let seconds = averageShortBreakDuration
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var averageLongBreakDuration: Int {
        guard longBreaksCompleted > 0 else { return 0 }
        return totalLongBreakTimeSeconds / longBreaksCompleted
    }
    
    var averageLongBreakDurationFormatted: String {
        let seconds = averageLongBreakDuration
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var longestFocusSessionFormatted: String {
        let seconds = longestFocusSessionSeconds
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
}

struct FocusView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    @State private var showProfile: Bool = false
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timeRemaining: Int = 1500
    @State private var currentMode: PomodoroMode = .work
    @State private var completedPomodoros: Int = 0
    @State private var timer: Timer?
    @State private var cyclePosition: Int = 1 // Position in the 1-8 cycle
    @State private var isAutoCycleMode: Bool = true
    @StateObject private var noiseGenerator = NoiseGenerator()
    private let bellPlayer = BellPlayer()
    @State private var showNoiseSettings = false
    @State private var showDurationSettings = false
    @State private var distractionCount: Int = 0
    
    // Custom durations (in seconds)
    @AppStorage("focusDuration") private var focusDuration: Int = 1500 // 25 minutes
    @AppStorage("shortBreakDuration") private var shortBreakDuration: Int = 300 // 5 minutes
    @AppStorage("longBreakDuration") private var longBreakDuration: Int = 900 // 15 minutes
    
    // Statistics tracking
    @AppStorage("focusStats") private var focusStatsData: Data = Data()
    @State private var sessionStartTime: Date?
    @StateObject private var userStatsManager = UserStatsManager()
    @StateObject private var sessionManager = SessionManager.shared
    
    private var focusStats: FocusStats {
        get {
            if let decoded = try? JSONDecoder().decode(FocusStats.self, from: focusStatsData) {
                return decoded
            }
            return FocusStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                focusStatsData = encoded
            }
        }
    }
    
    // Theme colors that react to system color scheme changes
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }
    
    private var usesDarkAppearance: Bool {
        themeManager.colorScheme(for: systemColorScheme) == .dark
    }
    
    private var controlSurfaceColor: Color {
        usesDarkAppearance ? themeColors.cardBackground.opacity(0.7) : themeColors.cardBackground.opacity(0.96)
    }
    
    private var controlBorderColor: Color {
        usesDarkAppearance ? Color.white.opacity(0.15) : themeColors.separator.opacity(0.85)
    }
    
    private func functionalButtonBackground(
        isActive: Bool,
        accentColor: Color,
        usesAccentFillWhenInactive: Bool = false,
        cornerRadius: CGFloat = 18
    ) -> some View {
        let wantsAccentFill = isActive || usesAccentFillWhenInactive
        
        let fillColors: [Color] = wantsAccentFill
        ? [
            accentColor.opacity(isActive ? 0.55 : 0.35),
            accentColor.opacity(isActive ? 0.25 : 0.18)
        ]
        : [
            controlSurfaceColor.opacity(usesDarkAppearance ? 1.0 : 0.95),
            controlSurfaceColor.opacity(usesDarkAppearance ? 0.75 : 0.8)
        ]
        
        let strokeColors: [Color] = wantsAccentFill
        ? [
            accentColor.opacity(1.0),
            accentColor.opacity(isActive ? 0.5 : 0.35)
        ]
        : [
            controlBorderColor.opacity(0.85),
            controlBorderColor.opacity(0.3)
        ]
        
        let shadowOpacity = usesDarkAppearance ? (isActive ? 0.55 : 0.4) : (isActive ? 0.22 : 0.15)
        let accentGlowOpacity = isActive ? 0.35 : (usesAccentFillWhenInactive ? 0.15 : 0.0)
        
        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: fillColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: strokeColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: wantsAccentFill ? 1.5 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: isActive ? 14 : 8,
                x: 0,
                y: isActive ? 10 : 5
            )
            .shadow(
                color: accentColor.opacity(accentGlowOpacity),
                radius: isActive ? 18 : 10,
                x: 0,
                y: isActive ? 10 : 4
            )
    }
    
    enum PomodoroMode {
        case work, shortBreak, longBreak
        
        var title: String {
            switch self {
            case .work: return "Focus"
            case .shortBreak: return "Short Break"
            case .longBreak: return "Long Break"
            }
        }
        
        var subtitle: String {
            switch self {
            case .work: return "Time to focus"
            case .shortBreak: return "Take a breather"
            case .longBreak: return "You earned it"
            }
        }
        
        var color: (red: Double, green: Double, blue: Double) {
            switch self {
            case .work: return (0.9, 0.6, 0.5)
            case .shortBreak: return (0.6, 0.8, 0.7)
            case .longBreak: return (0.7, 0.7, 0.9)
            }
        }
    }
    
    // Helper function to get duration for current mode
    func duration(for mode: PomodoroMode) -> Int {
        switch mode {
        case .work: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        }
    }
    
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                themeColors.backgroundTop,
                themeColors.backgroundBottom
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // Extracted computed properties to reduce body complexity
    private var currentModeColor: Color {
        Color(red: currentMode.color.red,
              green: currentMode.color.green,
              blue: currentMode.color.blue)
    }
    
    private var topTitleSection: some View {
        VStack(spacing: 12) {
            if !isRunning {
                Text(currentMode.title)
                    .font(.system(size: 34, weight: .light, design: .default))
                    .foregroundColor(themeColors.primaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                
                Text(currentMode.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(themeColors.secondaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 120)
        .padding(.top, 50)
    }
    
    private var timerCircleSection: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 12)
                .frame(width: 280, height: 280)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    currentModeColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            // Center circle
            Button(action: toggleTimer) {
                centerCircleContent
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 450)
    }
    
    private var centerCircleContent: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            currentModeColor.opacity(0.9),
                            Color(red: currentMode.color.red * 0.85,
                                  green: currentMode.color.green * 0.85,
                                  blue: currentMode.color.blue * 0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 220, height: 220)
                .shadow(color: currentModeColor.opacity(0.3),
                       radius: 30, x: 0, y: 10)
            
            VStack(spacing: 12) {
                if isRunning {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 52, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .monospacedDigit()
                    
                    if isPaused {
                        Text("PAUSED")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.5)
                    } else {
                        Text(currentMode.title.uppercased())
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.5)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "timer")
                            .font(.system(size: 42, weight: .thin))
                            .foregroundColor(.white)
                        
                        Text("START")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                }
            }
        }
    }
    
    private var settingsButtonsSection: some View {
        HStack(spacing: 12) {
            // Open duration settings modal
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDurationSettings = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                    Text("Durations")
                        .font(.system(size: 15, weight: .medium, design: .default))
                }
                .foregroundColor(themeColors.primaryText)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    functionalButtonBackground(
                        isActive: false,
                        accentColor: currentModeColor,
                        usesAccentFillWhenInactive: true,
                        cornerRadius: 20
                    )
                )
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Open noise settings modal
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showNoiseSettings = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: noiseGenerator.isEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                        .font(.system(size: 16))
                    Text("Sounds")
                        .font(.system(size: 15, weight: .medium, design: .default))
                }
                .foregroundColor(themeColors.primaryText)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(
                    functionalButtonBackground(
                        isActive: noiseGenerator.isEnabled,
                        accentColor: currentModeColor,
                        usesAccentFillWhenInactive: false,
                        cornerRadius: 24
                    )
                )
                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var controlButtonsSection: some View {
        VStack(spacing: 12) {
            if isRunning && currentMode == .work {
                // Distraction button (only during focus sessions)
                Button(action: {
                    distractionCount += 1
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 14))
                        Text("Distracted (\(distractionCount))")
                            .font(.system(size: 14, weight: .medium, design: .default))
                    }
                    .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.9, green: 0.5, blue: 0.3).opacity(0.15))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack(spacing: 16) {
                if isRunning {
                    Button(action: resetTimer) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14))
                            Text(isAutoCycleMode ? "End Cycle" : "Reset")
                                .font(.system(size: 16, weight: .regular, design: .default))
                        }
                        .foregroundColor(themeColors.secondaryText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(controlSurfaceColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(controlBorderColor, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    modeSelectorSection
                }
            }
        }
    }
    
    private var modeSelectorSection: some View {
        VStack(spacing: 12) {
            // Auto-cycle toggle
            Button(action: { 
                withAnimation {
                    isAutoCycleMode.toggle()
                    if isAutoCycleMode {
                        cyclePosition = 1
                        currentMode = .work
                        timeRemaining = duration(for: currentMode)
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isAutoCycleMode ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                    Text("Auto-cycle mode")
                        .font(.system(size: 15, weight: .medium, design: .default))
                }
                .foregroundColor(themeColors.primaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    functionalButtonBackground(
                        isActive: isAutoCycleMode,
                        accentColor: currentModeColor,
                        usesAccentFillWhenInactive: false,
                        cornerRadius: 20
                    )
                )
                .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Mode selector when not in auto-cycle mode
            if !isAutoCycleMode {
                modeSelectionButtons
                    .transition(.opacity)
            }
        }
    }
    
    private var modeSelectionButtons: some View {
        HStack(spacing: 12) {
            Button(action: { selectMode(.work) }) {
                Text("Focus")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(themeColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        functionalButtonBackground(
                            isActive: currentMode == .work,
                            accentColor: currentModeColor,
                            usesAccentFillWhenInactive: false,
                            cornerRadius: 18
                        )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectMode(.shortBreak) }) {
                Text("Rest")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(themeColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        functionalButtonBackground(
                            isActive: currentMode == .shortBreak,
                            accentColor: currentModeColor,
                            usesAccentFillWhenInactive: false,
                            cornerRadius: 18
                        )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectMode(.longBreak) }) {
                Text("Long Rest")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(themeColors.primaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        functionalButtonBackground(
                            isActive: currentMode == .longBreak,
                            accentColor: currentModeColor,
                            usesAccentFillWhenInactive: false,
                            cornerRadius: 18
                        )
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
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
    private var noiseSettingsOverlay: some View {
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
                NoiseOptionsModal(
                    isPresented: $showNoiseSettings,
                    noiseGenerator: noiseGenerator,
                    accentColor: currentModeColor,
                    isRunning: isRunning,
                    title: "Focus Sounds"
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(2)
        }
    }
    
    @ViewBuilder
    private var durationSettingsOverlay: some View {
        if showDurationSettings {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDurationSettings = false
                        }
                    }
                DurationSettingsModal(
                    isPresented: $showDurationSettings,
                    focusDuration: $focusDuration,
                    shortBreakDuration: $shortBreakDuration,
                    longBreakDuration: $longBreakDuration,
                    accentColor: currentModeColor,
                    isRunning: isRunning,
                    onDurationChanged: {
                        // Update timeRemaining if not running
                        if !isRunning {
                            timeRemaining = duration(for: currentMode)
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(2)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                topTitleSection
                
                Spacer()
                
                timerCircleSection
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 24) {
                    // Settings buttons (always visible)
                    VStack(spacing: 12) {
                        settingsButtonsSection
                    }
                    .transition(.opacity)
                    
                    controlButtonsSection
                }
                .frame(height: 155)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .swipeDownToOpenProfile(isDisabled: showNoiseSettings || showDurationSettings) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                showProfile = true
            }
        }
        .topSlideCover(isPresented: $showProfile) {
            ProfileView(
                onDismiss: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showProfile = false
                    }
                },
                isPresented: $showProfile
            )
            .environmentObject(themeManager)
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view
                    .toolbar(showProfile ? .hidden : .visible, for: .tabBar)
            } else {
                view
            }
        }
        .overlay(infoMessageOverlay)
        .overlay(noiseSettingsOverlay)
        .overlay(durationSettingsOverlay)
        .onChange(of: showNoiseSettings) { isPresented in
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": isPresented]
            )
        }
        .onAppear {
            // Initialize timeRemaining from stored duration on first load
            if !isRunning {
                timeRemaining = duration(for: currentMode)
            }
        }
        .onChange(of: focusDuration) { _ in
            // Update timeRemaining when focusDuration changes (if not running)
            if !isRunning && currentMode == .work {
                timeRemaining = duration(for: currentMode)
            }
        }
        .onChange(of: shortBreakDuration) { _ in
            // Update timeRemaining when shortBreakDuration changes (if not running)
            if !isRunning && currentMode == .shortBreak {
                timeRemaining = duration(for: currentMode)
            }
        }
        .onChange(of: longBreakDuration) { _ in
            // Update timeRemaining when longBreakDuration changes (if not running)
            if !isRunning && currentMode == .longBreak {
                timeRemaining = duration(for: currentMode)
            }
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": false]
            )
        }
    }
    
    var progress: CGFloat {
        let totalTime = Double(duration(for: currentMode))
        let remaining = Double(timeRemaining)
        return CGFloat(1.0 - (remaining / totalTime))
    }
    
    func toggleTimer() {
        if isRunning && !isPaused {
            pauseTimer()
        } else if isPaused {
            resumeTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        isRunning = true
        isPaused = false
        sessionStartTime = Date()
        distractionCount = 0 // Reset distraction count for new session
        
        // Play start bell
        bellPlayer.playBell()
        
        // Start noise if enabled
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
                
                // Trigger fade-out when 1 second remains
                if timeRemaining == 1 && noiseGenerator.isEnabled {
                    noiseGenerator.fadeOut(duration: 1.0)
                }
            } else {
                completeSession()
            }
        }
    }
    
    func pauseTimer() {
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        // Pause noise
        if noiseGenerator.isEnabled {
            noiseGenerator.stopNoise()
        }
    }
    
    func resumeTimer() {
        isPaused = false
        startTimer()
    }
    
    func resetTimer() {
        // Track statistics before resetting (not completed - abandoned)
        trackSessionTime(completed: false)
        
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        sessionStartTime = nil
        distractionCount = 0
        
        // Stop noise
        if noiseGenerator.isEnabled {
            noiseGenerator.stopNoise()
        }
        
        if isAutoCycleMode {
            // Reset to beginning of cycle
            cyclePosition = 1
            currentMode = .work
        }
        
        timeRemaining = duration(for: currentMode)
    }
    
    private func trackSessionTime(completed: Bool = false) {
        // Track statistics - always track time, only count as completed if session lasted at least 30 seconds
        if let startTime = sessionStartTime {
            let endTime = Date()
            let sessionDuration = Int(endTime.timeIntervalSince(startTime))
            if sessionDuration > 0 {
                var stats = focusStats
                
                // Always add time spent
                if currentMode == .work {
                    stats.totalFocusTimeSeconds += sessionDuration
                    // Only count as completed session if it lasted at least 30 seconds
                    if sessionDuration >= 30 {
                        stats.focusSessionsCompleted += 1
                        
                        // Update longest focus session if this one is longer
                        if sessionDuration > stats.longestFocusSessionSeconds {
                            stats.longestFocusSessionSeconds = sessionDuration
                        }
                        
                        // Record session in UserStatsManager for streak tracking
                        userStatsManager.recordSession(activityType: .focus, durationSeconds: sessionDuration)
                        
                        // Create enhanced session with metadata
                        var meta = EnhancedSession.SessionMetadata()
                        meta.plannedDuration = duration(for: currentMode)
                        meta.completed = completed
                        meta.distractions = distractionCount
                        
                        // Track content usage if noise was enabled
                        if noiseGenerator.isEnabled {
                            meta.contentId = noiseGenerator.selectedNoiseDescription
                            meta.contentDuration = sessionDuration
                        }
                        
                        let enhancedSession = EnhancedSession(
                            type: .focus,
                            start: startTime,
                            end: endTime,
                            meta: meta
                        )
                        
                        // Save enhanced session
                        Task { @MainActor in
                            sessionManager.saveSession(enhancedSession)
                        }
                    }
                } else {
                    stats.totalRestTimeSeconds += sessionDuration
                    
                    // Track break type time
                    if currentMode == .shortBreak {
                        stats.totalShortBreakTimeSeconds += sessionDuration
                    } else if currentMode == .longBreak {
                        stats.totalLongBreakTimeSeconds += sessionDuration
                    }
                    
                    // Record rest sessions too
                    if sessionDuration >= 30 {
                        stats.restSessionsCompleted += 1
                        
                        // Track break type
                        if currentMode == .shortBreak {
                            stats.shortBreaksCompleted += 1
                        } else if currentMode == .longBreak {
                            stats.longBreaksCompleted += 1
                        }
                        
                        userStatsManager.recordSession(activityType: .rest, durationSeconds: sessionDuration)
                    }
                }
                
                // Update the stored data directly
                if let encoded = try? JSONEncoder().encode(stats) {
                    focusStatsData = encoded
                }
            }
        }
    }
    
    func completeSession() {
        timer?.invalidate()
        timer = nil
        
        // Stop current noise
        if noiseGenerator.isEnabled {
            noiseGenerator.stopNoise()
        }
        
        // Track statistics (completed successfully)
        trackSessionTime(completed: true)
        
        if currentMode == .work {
            completedPomodoros += 1
        }
        
        if isAutoCycleMode {
            // Automatically advance to next phase in cycle
            advanceCycle()
            // Automatically start the next session
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startTimer()
            }
        } else {
            isRunning = false
            isPaused = false
            // Manual mode - suggest next mode
            if currentMode == .work {
                if completedPomodoros % 4 == 0 {
                    currentMode = .longBreak
                } else {
                    currentMode = .shortBreak
                }
            } else {
                currentMode = .work
            }
            timeRemaining = duration(for: currentMode)
            distractionCount = 0 // Reset for next session
        }
    }
    
    func advanceCycle() {
        cyclePosition += 1
        if cyclePosition > 8 {
            cyclePosition = 1 // Restart cycle
        }
        
        // Set mode based on cycle position with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            switch cyclePosition {
            case 1, 3, 5, 7: // Work sessions
                currentMode = .work
            case 2, 4, 6: // Short breaks
                currentMode = .shortBreak
            case 8: // Long break
                currentMode = .longBreak
            default:
                currentMode = .work
            }
        }
        
        timeRemaining = duration(for: currentMode)
    }
    
    func selectMode(_ mode: PomodoroMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMode = mode
            timeRemaining = duration(for: mode)
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Modal for Focus Sounds
struct NoiseOptionsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var noiseGenerator: NoiseGenerator
    let accentColor: Color
    let isRunning: Bool
    let title: String
    @State private var showMixerSheet = false
    
    var body: some View {
        let modalWidth: CGFloat = 400
        let modalHeight: CGFloat = 680
        let toggleBinding = Binding(
            get: { noiseGenerator.isEnabled },
            set: { newValue in
                noiseGenerator.isEnabled = newValue
                if newValue {
                    if isRunning { noiseGenerator.startNoise() }
                } else {
                    noiseGenerator.stopNoise()
                }
            }
        )
        
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Toggle(isOn: toggleBinding) {
                    EmptyView()
                }
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                .accessibilityLabel("Focus sounds toggle")
            }
            
            ScrollView {
                VStack(spacing: 12) {
                        ForEach(SoundCategory.allCategories, id: \.name) { category in
                            FocusCategorySection(
                                category: category,
                                selectedNoiseTypes: noiseGenerator.selectedNoiseTypes,
                                accentColor: accentColor,
                                onSoundSelected: { noiseType in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        noiseGenerator.toggleNoiseType(noiseType)
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
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMixerSheet = true
                }
            }) {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor, lineWidth: 1.2)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                    .overlay(
                        Text("Mix")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accentColor)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .frame(width: modalWidth, height: modalHeight)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: 12)
        )
        .sheet(isPresented: $showMixerSheet) {
            SoundMixerSheetView(
                noiseGenerator: noiseGenerator,
                accentColor: accentColor
            )
        }
    }
}

// MARK: - Focus Category Section Component
struct FocusCategorySection: View {
    let category: SoundCategory
    let selectedNoiseTypes: Set<NoiseGenerator.NoiseType>
    let accentColor: Color
    let onSoundSelected: (NoiseGenerator.NoiseType) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                Text(category.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(category.sounds, id: \.self) { noiseType in
                        SoundTileView(
                            noiseType: noiseType,
                            isSelected: selectedNoiseTypes.contains(noiseType),
                            accentColor: accentColor,
                            onTap: {
                                onSoundSelected(noiseType)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
    }
}

struct SoundMixerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var noiseGenerator: NoiseGenerator
    let accentColor: Color
    
    private var activeSounds: [NoiseGenerator.NoiseType] {
        noiseGenerator.selectedNoiseTypes
            .sorted { $0.description < $1.description }
    }
    
    private var hasMixableSounds: Bool {
        activeSounds.count > 1
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                ScrollView {
                    VStack(spacing: 18) {
                        if activeSounds.isEmpty {
                            MixEmptyStateView(
                                title: "No active sounds",
                                message: "Choose at least one sound from the Focus or Sleep sheet to begin mixing.",
                                accentColor: accentColor
                            )
                        } else if !hasMixableSounds {
                            MixEmptyStateView(
                                title: "Add one more layer",
                                message: "Turn on another sound to unlock the circular mixer and start shaping the blend.",
                                accentColor: accentColor
                            )
                        } else {
                            CircularMixControl(
                                noiseGenerator: noiseGenerator,
                                sounds: activeSounds,
                                accentColor: accentColor
                            )
                            .frame(height: 360)
                            .padding(.horizontal, 6)
                            
                            Text("Drag the glowing dot closer to a sound icon to boost it. Moving toward the center evens everything out.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.4, green: 0.45, blue: 0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                            
                            MixShareGrid(
                                noiseGenerator: noiseGenerator,
                                sounds: activeSounds,
                                accentColor: accentColor
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                }
                
                if hasMixableSounds {
                    Button(action: {
                        noiseGenerator.equalizeMix()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Balance Mix")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(accentColor.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .navigationTitle("Sound Mixer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(accentColor)
                }
            }
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view.presentationDetents([.medium, .large])
            } else {
                view
            }
        }
    }
    
}

private struct MixEmptyStateView: View {
    let title: String
    let message: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(accentColor)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            Text(message)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.5))
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
        )
    }
}

private struct CircularMixControl: View {
    @ObservedObject var noiseGenerator: NoiseGenerator
    let sounds: [NoiseGenerator.NoiseType]
    let accentColor: Color
    
    @State private var normalizedPosition: CGPoint = .zero
    @State private var isDragging = false
    
    private var mixSignature: [Float] {
        sounds.map { noiseGenerator.mixShare(for: $0) }
    }
    
    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let dialRadius = max((minSide / 2) - 12, 90)
            let controlRadius = max(dialRadius - 48, dialRadius * 0.65)
            let normalizedPoints = perimeterPositions()
            let dotPosition = CGPoint(
                x: center.x + normalizedPosition.x * controlRadius,
                y: center.y + normalizedPosition.y * controlRadius
            )
            
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.35),
                                accentColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: dialRadius * 2, height: dialRadius * 2)
                    .overlay(
                        Circle()
                            .fill(accentColor.opacity(0.05))
                            .frame(width: dialRadius * 2, height: dialRadius * 2)
                    )
                
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 8]))
                    .foregroundColor(accentColor.opacity(0.25))
                    .frame(width: controlRadius * 2, height: controlRadius * 2)
                
                ForEach(Array(sounds.enumerated()), id: \.element) { index, sound in
                    if index < normalizedPoints.count {
                        let basePoint = normalizedPoints[index]
                        let iconPosition = CGPoint(
                            x: center.x + basePoint.x * dialRadius,
                            y: center.y + basePoint.y * dialRadius
                        )
                        
                        Path { path in
                            path.move(to: iconPosition)
                            path.addLine(to: dotPosition)
                        }
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 46, height: 46)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .overlay(
                                Image(systemName: sound.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(accentColor)
                            )
                            .position(iconPosition)
                    }
                }
                
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.45)
                            ]),
                            center: .center,
                            startRadius: 2,
                            endRadius: 36
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: accentColor.opacity(0.35), radius: 18, x: 0, y: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
                            .frame(width: 34, height: 34)
                    )
                    .position(dotPosition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let vector = CGPoint(
                            x: value.location.x - center.x,
                            y: value.location.y - center.y
                        )
                        let normalized = normalize(vector: vector, maxRadius: controlRadius)
                        normalizedPosition = normalized
                        updateMixWeights(using: normalized)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .onAppear {
            normalizedPosition = normalizedPointFromMix()
        }
        .onChange(of: sounds) { _ in
            normalizedPosition = normalizedPointFromMix()
        }
        .onChange(of: mixSignature) { _ in
            guard !isDragging else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                normalizedPosition = normalizedPointFromMix()
            }
        }
    }
    
    private func perimeterPositions() -> [CGPoint] {
        guard !sounds.isEmpty else { return [] }
        let count = sounds.count
        return (0..<count).map { index in
            let angle = (Double(index) / Double(count)) * (.pi * 2) - .pi / 2
            return CGPoint(x: cos(angle), y: sin(angle))
        }
    }
    
    private func normalizedPointFromMix() -> CGPoint {
        guard !sounds.isEmpty else { return .zero }
        let positions = perimeterPositions()
        var result = CGPoint.zero
        
        for (index, share) in mixSignature.enumerated() where index < positions.count {
            let fraction = CGFloat(share)
            result.x += positions[index].x * fraction
            result.y += positions[index].y * fraction
        }
        return result
    }
    
    private func normalize(vector: CGPoint, maxRadius: CGFloat) -> CGPoint {
        guard maxRadius > 0 else { return .zero }
        var normalized = CGPoint(x: vector.x / maxRadius, y: vector.y / maxRadius)
        let length = normalized.magnitude
        if length > 1 {
            normalized.x /= length
            normalized.y /= length
        }
        return normalized
    }
    
    private func updateMixWeights(using normalized: CGPoint) {
        let positions = perimeterPositions()
        guard !positions.isEmpty else { return }
        
        var rawWeights: [NoiseGenerator.NoiseType: CGFloat] = [:]
        var total: CGFloat = 0
        let softness: CGFloat = 0.15
        
        for (index, sound) in sounds.enumerated() where index < positions.count {
            let distance = normalized.distance(to: positions[index])
            let weight = 1 / ((distance + softness) * (distance + softness))
            rawWeights[sound] = weight
            total += weight
        }
        
        guard total > 0 else { return }
        var scaled: [NoiseGenerator.NoiseType: Float] = [:]
        
        for sound in sounds {
            if let weight = rawWeights[sound] {
                let fraction = weight / total
                scaled[sound] = Float(fraction * 100)
            }
        }
        
        noiseGenerator.applyMix(weights: scaled)
    }
}

private struct MixShareGrid: View {
    @ObservedObject var noiseGenerator: NoiseGenerator
    let sounds: [NoiseGenerator.NoiseType]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mix Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.25, green: 0.3, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(sounds, id: \.self) { sound in
                    MixShareCard(
                        noiseType: sound,
                        share: noiseGenerator.mixShare(for: sound),
                        accentColor: accentColor
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MixShareCard: View {
    let noiseType: NoiseGenerator.NoiseType
    let share: Float
    let accentColor: Color
    
    private var shareText: String {
        "\(Int(round(share * 100)))%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: noiseType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.12))
                    )
                Text(noiseType.description)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Text(shareText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.6))
            }
            
            ProgressView(value: Double(share), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private extension CGPoint {
    var magnitude: CGFloat {
        sqrt(x * x + y * y)
    }
    
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

// MARK: - Duration Settings Modal
struct DurationSettingsModal: View {
    @Binding var isPresented: Bool
    @Binding var focusDuration: Int
    @Binding var shortBreakDuration: Int
    @Binding var longBreakDuration: Int
    let accentColor: Color
    let isRunning: Bool
    let onDurationChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Session Durations")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { isPresented = false }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.black.opacity(0.25))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(spacing: 16) {
                // Focus Duration Wheel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
                        Text("Focus Duration")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    FocusWheelPicker(
                        selectedSeconds: $focusDuration,
                        options: FocusWheelPicker.focusOptions
                    )
                    .frame(height: 140)
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.5 : 1.0)
                    .onChange(of: focusDuration) { _ in onDurationChanged() }
                }
                
                // Short Break Duration Wheel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                        Text("Short Break")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    FocusWheelPicker(
                        selectedSeconds: $shortBreakDuration,
                        options: FocusWheelPicker.shortBreakOptions
                    )
                    .frame(height: 140)
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.5 : 1.0)
                    .onChange(of: shortBreakDuration) { _ in onDurationChanged() }
                }
                
                // Long Break Duration Wheel
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.9))
                        Text("Long Break")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    FocusWheelPicker(
                        selectedSeconds: $longBreakDuration,
                        options: FocusWheelPicker.longBreakOptions
                    )
                    .frame(height: 140)
                    .disabled(isRunning)
                    .opacity(isRunning ? 0.5 : 1.0)
                    .onChange(of: longBreakDuration) { _ in onDurationChanged() }
                }
                
                if isRunning {
                    Text("⚠️ Durations can't be changed during a session")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.2)) { 
                    isPresented = false 
                } 
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accentColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            // Ensure selections are on valid options
            focusDuration = snapToNearest(focusDuration, options: FocusWheelPicker.focusOptions)
            shortBreakDuration = snapToNearest(shortBreakDuration, options: FocusWheelPicker.shortBreakOptions)
            longBreakDuration = snapToNearest(longBreakDuration, options: FocusWheelPicker.longBreakOptions)
        }
    }
    
    private func snapToNearest(_ value: Int, options: [Int]) -> Int {
        options.min(by: { abs($0 - value) < abs($1 - value) }) ?? value
    }
}

// MARK: - Focus Wheel Picker Components
private struct FocusWheelRow: View {
    let text: String
    let isSelected: Bool
    let distance: Int
    
    var body: some View {
        let opacity = max(0.25, 1.0 - 0.22 * Double(distance))
        let scale: CGFloat = isSelected ? 1.0 : max(0.9, 1.0 - 0.04 * CGFloat(distance))
        
        return Text(text)
            .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4).opacity(opacity))
            .scaleEffect(scale)
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
    }
}

private struct FocusWheelPicker: View {
    @Binding var selectedSeconds: Int
    let options: [Int]
    
    // Allowed options: 1 to 60 minutes in one-minute increments
    static let focusOptions: [Int] = Array(stride(from: 1 * 60, through: 60 * 60, by: 60))
    static let shortBreakOptions: [Int] = Array(stride(from: 1 * 60, through: 60 * 60, by: 60))
    static let longBreakOptions: [Int] = Array(stride(from: 1 * 60, through: 60 * 60, by: 60))
    
    var body: some View {
        let selectedIndex = options.firstIndex(of: selectedSeconds) ?? 0
        
        ZStack {
            // Top/bottom fade overlay
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .white.opacity(0.9), location: 0.0),
                    .init(color: .white.opacity(0.0), location: 0.25),
                    .init(color: .white.opacity(0.0), location: 0.75),
                    .init(color: .white.opacity(0.9), location: 1.0),
                ]),
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            // The actual wheel
            Picker("", selection: Binding(
                get: { selectedSeconds },
                set: { newVal in
                    if options.contains(newVal) {
                        selectedSeconds = newVal
                    } else {
                        // Snap to nearest valid
                        if let nearest = options.min(by: { abs($0 - newVal) < abs($1 - newVal) }) {
                            selectedSeconds = nearest
                        }
                    }
                }
            )) {
                ForEach(options.indices, id: \.self) { i in
                    let secs = options[i]
                    let dist = abs(i - selectedIndex)
                    FocusWheelRow(
                        text: label(for: secs),
                        isSelected: i == selectedIndex,
                        distance: dist
                    )
                    .tag(secs)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .clipped()
        }
    }
    
    private func label(for seconds: Int) -> String {
        let minutes = seconds / 60
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }
}

#Preview {
    FocusView()
}
