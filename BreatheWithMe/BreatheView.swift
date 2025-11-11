//
//  BreatheView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

// MARK: - Data Model
struct BreatheStats: Codable {
    var sessionsCompleted: Int = 0
    var totalTimeSeconds: Int = 0
    var sessions478: Int = 0  // Count of 4-7-8 technique sessions
    var standardSessions: Int = 0  // Count of standard breathing sessions
    var longestSessionSeconds: Int = 0  // Longest session duration
    
    var totalTimeFormatted: String {
        let hours = totalTimeSeconds / 3600
        let minutes = (totalTimeSeconds % 3600) / 60
        let seconds = totalTimeSeconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var averageDuration: Int {
        guard sessionsCompleted > 0 else { return 0 }
        return totalTimeSeconds / sessionsCompleted
    }
    
    var averageDurationFormatted: String {
        let seconds = averageDuration
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var longestSessionFormatted: String {
        let seconds = longestSessionSeconds
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
}

struct BreatheView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    @State private var showProfile: Bool = false
    @State private var isBreathing = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var remainingTime: Int = 0
    @State private var selectedDuration: Int = 60
    @State private var timer: Timer?
    @State private var totalElapsedTime: Double = 0
    @State private var bellSoundEnabled: Bool = true
    private let bellPlayer = BellPlayer()
    @State private var breathInterval: Double = 4.0
    @State private var isAdjustingInterval: Bool = false
    @State private var lastDragAngle: Double? = nil
    
    // Statistics tracking
    @AppStorage("breatheStats") private var breatheStatsData: Data = Data()
    @State private var sessionStartTime: Date?
    @StateObject private var userStatsManager = UserStatsManager()
    @StateObject private var sessionManager = SessionManager.shared
    @State private var hasRequestedHealthKit = false
    
    // Stress reporting
    @State private var showPreStressPicker = false
    @State private var showPostStressPicker = false
    @State private var preStressLevel: Int?
    @State private var postStressLevel: Int?
    
    private var breatheStats: BreatheStats {
        get {
            if let decoded = try? JSONDecoder().decode(BreatheStats.self, from: breatheStatsData) {
                return decoded
            }
            return BreatheStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                breatheStatsData = encoded
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
        usesDarkAppearance ? themeColors.cardBackground.opacity(0.7) : themeColors.cardBackground.opacity(0.95)
    }
    
    private var controlBorderColor: Color {
        usesDarkAppearance ? Color.white.opacity(0.15) : themeColors.separator.opacity(0.85)
    }
    
    private func functionalButtonBackground(
        isActive: Bool,
        usesAccentFillWhenInactive: Bool = false,
        cornerRadius: CGFloat = 18
    ) -> some View {
        let wantsAccentFill = isActive || usesAccentFillWhenInactive
        
        let fillColors: [Color] = wantsAccentFill
        ? [
            themeColors.accent.opacity(isActive ? 0.55 : 0.35),
            themeColors.accent.opacity(isActive ? 0.25 : 0.18)
        ]
        : [
            controlSurfaceColor.opacity(usesDarkAppearance ? 1.0 : 0.95),
            controlSurfaceColor.opacity(usesDarkAppearance ? 0.75 : 0.8)
        ]
        
        let strokeColors: [Color] = wantsAccentFill
        ? [
            themeColors.accent.opacity(1.0),
            themeColors.accent.opacity(isActive ? 0.5 : 0.35)
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
                color: themeColors.accent.opacity(accentGlowOpacity),
                radius: isActive ? 18 : 10,
                x: 0,
                y: isActive ? 10 : 4
            )
    }

    // Show/hide the duration picker window
    @State private var showDurationPicker: Bool = false
    // 4-7-8 info modal
    @State private var show478Modal: Bool = false
    
    // 4-7-8 mode toggle + per-phase durations
    @State private var use478: Bool = false
    @State private var inhaleDur: Double = 4.0
    @State private var holdDur: Double = 0.0
    @State private var exhaleDur: Double = 4.0
    
    // Preset chips kept for compatibility, but the wheel offers more granular options
    let durations = [30, 60, 120, 300]
    
    enum BreathingPhase {
        case inhale, hold, exhale
        
        var text: String {
            switch self {
            case .inhale: return "Breathe In"
            case .hold:   return "Hold"
            case .exhale: return "Breathe Out"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Soft gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColors.backgroundTop,
                    themeColors.backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with fixed height
                VStack(spacing: 12) {
                    if !isBreathing {
                        Text("Breathe")
                            .font(.system(size: 34, weight: .light, design: .default))
                            .foregroundColor(themeColors.primaryText)
                            .transition(.opacity .combined(with: .move(edge: .top)))
                        
                        Text("Find your calm")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(themeColors.secondaryText)
                            .transition(.opacity .combined(with: .move(edge: .top)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 120)
                .padding(.top, 50)
                
                Spacer()
                
                // Main breathing circle
                ZStack {
                    // Multiple layered circles for depth
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.6, green: 0.75, blue: 0.9).opacity(0.15 - Double(index) * 0.04),
                                        Color(red: 0.7, green: 0.82, blue: 0.95).opacity(0.08 - Double(index) * 0.02),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150 + CGFloat(index) * 30
                                )
                            )
                            .frame(width: 300 + CGFloat(index) * 60, height: 300 + CGFloat(index) * 60)
                            .scaleEffect(isBreathing ? scale * (1.0 + Double(index) * 0.1) : 1.0)
                            .opacity(isBreathing ? opacity * (1.0 - Double(index) * 0.15) : 0.4)
                            .animation(
                                isBreathing ? .easeInOut(duration: currentPhaseDuration()) : .easeInOut(duration: 0.5),
                                value: scale
                            )
                    }
                    
                    // Central breathing circle
                    Button(action: toggleBreathing) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeColors.accent,
                                            themeColors.accent.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 220, height: 220)
                                .scaleEffect(isBreathing ? scale : 1.0)
                                .shadow(color: themeColors.accent.opacity(0.3), radius: 30, x: 0, y: 10)
                                .animation(
                                    isBreathing ? .easeInOut(duration: currentPhaseDuration()) : .easeInOut(duration: 0.5),
                                    value: scale
                                )
                            
                            // Inner circle
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 180, height: 180)
                                .scaleEffect(isBreathing ? scale : 1.0)
                                .animation(
                                    isBreathing ? .easeInOut(duration: currentPhaseDuration()) : .easeInOut(duration: 0.5),
                                    value: scale
                                )
                            
                            VStack(spacing: 8) {
                                if isBreathing {
                                    Text(currentPhase.text.uppercased())
                                        .font(.system(size: 18, weight: .medium, design: .default))
                                        .foregroundColor(.white)
                                        .tracking(2)
                                        .transition(.opacity)
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "wind.circle")
                                            .font(.system(size: 42, weight: .thin))
                                            .foregroundColor(.white)
                                        
                                        if isAdjustingInterval && !use478 {
                                            Text("\(formatIntervalNumber(breathInterval))")
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                                .foregroundColor(.white)
                                                .tracking(2)
                                        } else {
                                            Text("START")
                                                .font(.system(size: 16, weight: .medium, design: .default))
                                                .foregroundColor(.white)
                                                .tracking(2)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .overlay(
                    GeometryReader { proxy in
                        // Outer interactive ring for one-finger spin
                        let size = proxy.size
                        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
                        let outerDiameter: CGFloat = 260
                        let innerDiameter: CGFloat = 220
                        ZStack {
                            // Visual feedback ring (only visible while adjusting)
                            Circle()
                                .stroke(isAdjustingInterval ? Color.white.opacity(0.25) : Color.clear, lineWidth: 36)
                                .frame(width: outerDiameter, height: outerDiameter)
                                .position(x: center.x, y: center.y)
                        }
                        .contentShape({ () -> Path in
                            var path = Path()
                            path.addEllipse(in: CGRect(x: center.x - outerDiameter/2, y: center.y - outerDiameter/2, width: outerDiameter, height: outerDiameter))
                            path.addEllipse(in: CGRect(x: center.x - innerDiameter/2, y: center.y - innerDiameter/2, width: innerDiameter, height: innerDiameter))
                            return path
                        }(), eoFill: true)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { value in
                                    guard !isBreathing, !use478 else { return } // disable adjusting when 4-7-8 is active
                                    isAdjustingInterval = true
                                    let dx = value.location.x - center.x
                                    let dy = value.location.y - center.y
                                    let angle = Double(atan2(dy, dx))
                                    if let last = lastDragAngle {
                                        var delta = angle - last
                                        if delta > .pi { delta -= 2 * .pi }
                                        if delta < -.pi { delta += 2 * .pi }
                                        let secondsPerRevolution = 4.0 // 360° spin adjusts by 4 seconds
                                        let deltaSeconds = delta / (2 * .pi) * secondsPerRevolution
                                        breathInterval = max(2.0, breathInterval + deltaSeconds)
                                        // keep two-phase durations in sync when not in 4-7-8 mode
                                        inhaleDur = breathInterval
                                        exhaleDur = breathInterval
                                        holdDur = 0.0
                                    }
                                    lastDragAngle = angle
                                }
                                .onEnded { _ in
                                    lastDragAngle = nil
                                    isAdjustingInterval = false
                                }
                        )
                        .allowsHitTesting(!isBreathing && !use478)
                    }
                )
                .frame(height: 450)
                
                Spacer()
                
                // Bottom section - Duration and Timer
                VStack(spacing: 20) {
                    if isBreathing {
                        VStack(spacing: 8) {
                            Text("\(formatTime(remainingTime))")
                                .font(.system(size: 48, weight: .thin, design: .default))
                                .foregroundColor(themeColors.primaryText)
                            
                            Button(action: stopBreathing) {
                                Text("Stop")
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundColor(themeColors.accent)
                                    .padding(.horizontal, 30)
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
                        }
                        .transition(.opacity)
                    } else {
                        VStack(spacing: 12) {
                            // Bell sound toggle
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    bellSoundEnabled.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: bellSoundEnabled ? "bell.fill" : "bell.slash")
                                        .font(.system(size: 16))
                                    Text("Transition Sounds")
                                        .font(.system(size: 15, weight: .medium, design: .default))
                                }
                                .foregroundColor(themeColors.primaryText)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 10)
                                .background(
                                    functionalButtonBackground(
                                        isActive: bellSoundEnabled,
                                        usesAccentFillWhenInactive: false,
                                        cornerRadius: 24
                                    )
                                )
                                .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Controls row: DURATION + 4-7-8
                            HStack(spacing: 10) {
                                // DURATION button
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedDuration = snapToAllowed(selectedDuration)
                                        showDurationPicker = true
                                    }
                                }) {
                                    if #available(iOS 16.0, *) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "clock")
                                                .font(.system(size: 16))
                                            Text("Duration")
                                            if use478 {
                                                // subtle badge indicating 4-7-8 is active (affects phases, not duration)
                                                Text("4-7-8")
                                                    .font(.system(size: 15, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        Capsule().fill(Color.white.opacity(0.2))
                                                    )
                                            }
                                        }
                                        .font(.system(size: 15, weight: .medium, design: .default))
                                        .foregroundColor(themeColors.primaryText)
                                        .tracking(1.5)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            functionalButtonBackground(
                                                isActive: false,
                                                usesAccentFillWhenInactive: true,
                                                cornerRadius: 16
                                            )
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    } else {
                                        // Fallback on earlier versions
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 4-7-8 button
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        show478Modal = true
                                    }
                                }) {
                                    Text("4-7-8")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(themeColors.primaryText)
                                        .tracking(1.0)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            functionalButtonBackground(
                                                isActive: use478,
                                                usesAccentFillWhenInactive: false,
                                                cornerRadius: 16
                                            )
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.top, 4)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(height: 155)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .swipeDownToOpenProfile {
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
        // Overlays: Duration wheel + 4-7-8 modal
        .overlay(
            Group {
                if showDurationPicker {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showDurationPicker = false
                                }
                            }
                        DurationPickerModal(
                            isPresented: $showDurationPicker,
                            selectedDuration: $selectedDuration
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(2)
                }
            }
        )
        .overlay(
            Group {
                if show478Modal {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .transition(.opacity)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    show478Modal = false
                                }
                            }
                        FourSevenEightModal(
                            isPresented: $show478Modal,
                            use478: $use478,
                            applyPattern: apply478Pattern,
                            disablePattern: disable478Pattern
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(3)
                }
                
                // Pre-stress picker - subtle top card
                if showPreStressPicker {
                    VStack {
                        StressLevelPickerModal(
                            isPresented: $showPreStressPicker,
                            title: "How stressed are you?",
                            selectedLevel: Binding(
                                get: { preStressLevel },
                                set: { newValue in
                                    preStressLevel = newValue
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showPreStressPicker = false
                                    }
                                }
                            )
                        )
                        .transition(.opacity)
                        Spacer()
                    }
                    .zIndex(4)
                }
                
                // Post-stress picker - subtle top card
                if showPostStressPicker {
                    VStack {
                        StressLevelPickerModal(
                            isPresented: $showPostStressPicker,
                            title: "How do you feel now?",
                            selectedLevel: Binding(
                                get: { postStressLevel },
                                set: { newValue in
                                    postStressLevel = newValue
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showPostStressPicker = false
                                    }
                                    // Reset stress levels for next session after post-stress is set
                                    if newValue != nil {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            self.preStressLevel = nil
                                            self.postStressLevel = nil
                                        }
                                    }
                                }
                            )
                        )
                        .transition(.opacity)
                        Spacer()
                    }
                    .zIndex(4)
                }
            }
        )
        .onAppear {
            guard !hasRequestedHealthKit else { return }
            hasRequestedHealthKit = true
            Task {
                try? await HealthKitManager.shared.requestAuthorization()
            }
        }
    }
    
    // MARK: - Breathing state control
    
    func toggleBreathing() {
        if isBreathing {
            stopBreathing()
        } else {
            startBreathing()
        }
    }
    
    func startBreathing() {
        // Start breathing immediately - don't wait for stress level
        isBreathing = true
        remainingTime = selectedDuration
        totalElapsedTime = 0
        currentPhase = .inhale
        sessionStartTime = Date()
        
        updateBreathingAnimation()
        if bellSoundEnabled { bellPlayer.playBell() }
        
        // Show pre-stress picker subtly if not already set (non-blocking)
        if preStressLevel == nil {
            // Show after a brief delay to not interrupt the breathing start
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.isBreathing && self.preStressLevel == nil {
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.showPreStressPicker = true
                    }
                }
            }
        }
        
        // Timer updates at 0.1 second intervals for smooth phase transitions
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.totalElapsedTime += 0.1
            self.updateCurrentPhase()
            let newRemainingTime = max(0, self.selectedDuration - Int(self.totalElapsedTime))
            if newRemainingTime != self.remainingTime {
                self.remainingTime = newRemainingTime
            }
            if self.remainingTime <= 0 {
                self.stopBreathing()
            }
        }
    }
    
    func stopBreathing() {
        isBreathing = false
        timer?.invalidate()
        timer = nil
        scale = 1.0
        opacity = 1.0
        currentPhase = .inhale
        
        // Track statistics - always track time, only count as completed if session lasted at least 10 seconds
        var sessionDuration: Int = 0
        if let startTime = sessionStartTime {
            let endTime = Date()
            sessionDuration = Int(endTime.timeIntervalSince(startTime))
            if sessionDuration > 0 {
                var stats = breatheStats
                
                // Always add time spent
                stats.totalTimeSeconds += sessionDuration
                
                // Only count as completed session if it lasted at least 10 seconds
                if sessionDuration >= 10 {
                    stats.sessionsCompleted += 1
                    
                    // Track session type (4-7-8 vs standard)
                    if use478 {
                        stats.sessions478 += 1
                    } else {
                        stats.standardSessions += 1
                    }
                    
                    // Update longest session if this one is longer
                    if sessionDuration > stats.longestSessionSeconds {
                        stats.longestSessionSeconds = sessionDuration
                    }
                    
                    // Record session in UserStatsManager for streak tracking
                    userStatsManager.recordSession(activityType: .breathe, durationSeconds: sessionDuration)
                    
                    // Create enhanced session with metadata
                    var meta = EnhancedSession.SessionMetadata()
                    
                    // Track protocol
                    if use478 {
                        meta.protocolId = "478"
                    } else if inhaleDur == exhaleDur && holdDur == 0 {
                        meta.protocolId = "equal"
                    } else if exhaleDur == inhaleDur * 2 {
                        meta.protocolId = "2_1_exhale"
                    } else if inhaleDur == holdDur && holdDur == exhaleDur {
                        meta.protocolId = "box_\(Int(inhaleDur))_\(Int(holdDur))_\(Int(exhaleDur))_\(Int(holdDur))"
                    }
                    
                    // Track stress levels
                    meta.preStressLevel = preStressLevel
                    meta.postStressLevel = postStressLevel
                    
                    let enhancedSession = EnhancedSession(
                        type: .breathing,
                        start: startTime,
                        end: endTime,
                        meta: meta
                    )
                    
                    // Save enhanced session
                    Task { @MainActor in
                        sessionManager.saveSession(enhancedSession)
                    }
                    Task {
                        try? await HealthKitManager.shared.saveMindfulSession(start: startTime, end: endTime)
                    }
                }
                
                // Update the stored data directly
                if let encoded = try? JSONEncoder().encode(stats) {
                    breatheStatsData = encoded
                }
            }
        }
        
        totalElapsedTime = 0
        let sessionWasCompleted = sessionDuration >= 10
        sessionStartTime = nil
        
        // Show post-stress picker subtly if session was completed (non-blocking)
        if sessionWasCompleted && postStressLevel == nil {
            // Show after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.3)) {
                    self.showPostStressPicker = true
                }
            }
        } else {
            // Reset stress levels for next session only if we're not showing post-stress picker
            if !sessionWasCompleted {
                preStressLevel = nil
                postStressLevel = nil
            }
        }
    }
    
    func updateCurrentPhase() {
        if use478 {
            // 3-phase cycle: 4 (inhale) + 7 (hold) + 8 (exhale)
            let cycle = inhaleDur + holdDur + exhaleDur
            let t = totalElapsedTime.truncatingRemainder(dividingBy: cycle)
            let newPhase: BreathingPhase
            if t < inhaleDur {
                newPhase = .inhale
            } else if t < inhaleDur + holdDur {
                newPhase = .hold
            } else {
                newPhase = .exhale
            }
            if newPhase != currentPhase {
                currentPhase = newPhase
                updateBreathingAnimation()
                if bellSoundEnabled { bellPlayer.playBell() }
            }
        } else {
            // 2-phase cycle: inhale(breathInterval) -> exhale(breathInterval)
            let cycle = breathInterval * 2.0
            let t = totalElapsedTime.truncatingRemainder(dividingBy: cycle)
            let newPhase: BreathingPhase = (t < breathInterval) ? .inhale : .exhale
            if newPhase != currentPhase {
                currentPhase = newPhase
                updateBreathingAnimation()
                if bellSoundEnabled { bellPlayer.playBell() }
            }
        }
    }
    
    func currentPhaseDuration() -> Double {
        switch currentPhase {
        case .inhale: return use478 ? inhaleDur : breathInterval
        case .hold:   return use478 ? holdDur   : 0.0
        case .exhale: return use478 ? exhaleDur : breathInterval
        }
    }
    
    func updateBreathingAnimation() {
        switch currentPhase {
        case .inhale:
            withAnimation(.easeInOut(duration: currentPhaseDuration())) {
                scale = 1.4
                opacity = 1.0
            }
        case .hold:
            // Keep size steady during hold; slight opacity adjustment for feedback
            withAnimation(.linear(duration: max(0.01, currentPhaseDuration()))) {
                scale = 1.4
                opacity = 0.9
            }
        case .exhale:
            withAnimation(.easeInOut(duration: currentPhaseDuration())) {
                scale = 0.8
                opacity = 0.6
            }
        }
    }
    
    // MARK: - Formatting helpers
    
    func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)"
        } else {
            let minutes = seconds / 60
            return "\(minutes)"
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return String(format: "%d:%02d", mins, secs)
        } else {
            return "\(secs)"
        }
    }
    
    func formatIntervalNumber(_ seconds: Double) -> String {
        let rounded = (seconds * 10).rounded() / 10
        if abs(rounded.rounded() - rounded) < 0.0001 {
            return "\(Int(rounded))"
        } else {
            return String(format: "%.1f", rounded)
        }
    }
    
    /// Snap an arbitrary number of seconds to your allowed grid:
    ///  - 15s, 30s, 45s, 60s
    ///  - 2m, 3m, ..., 60m (whole-minute)
    private func snapToAllowed(_ seconds: Int) -> Int {
        let maxSec = 3600
        if seconds <= 60 {
            // nearest 15s (15..60)
            let rounded = max(15, min(60, Int(round(Double(seconds) / 15.0) * 15.0)))
            return rounded
        } else {
            // nearest whole minute (>= 2 min)
            let rounded = Int(round(Double(seconds) / 60.0) * 60.0)
            return max(120, min(maxSec, rounded))
        }
    }
    
    // MARK: - 4-7-8 handlers
    
    private func apply478Pattern() {
        use478 = true
        inhaleDur = 4.0
        holdDur = 7.0
        exhaleDur = 8.0
        show478Modal = false
    }
    
    private func disable478Pattern() {
        use478 = false
        holdDur = 0.0
        inhaleDur = breathInterval
        exhaleDur = breathInterval
        show478Modal = false
    }
}

// MARK: - Modal for Duration (wheel picker with fading neighbors)
private struct DurationPickerModal: View {
    @Binding var isPresented: Bool
    @Binding var selectedDuration: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 16))
                Text("Duration")
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
            
            // Wheel picker
            WheelDurationPicker(selectedSeconds: $selectedDuration)
                .padding(.horizontal, 4)
                .frame(height: 180)
            
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isPresented = false } }) {
                Text("Done")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.65, green: 0.8, blue: 0.92))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: 340)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            // Ensure selection is on a valid option
            let valid = WheelDurationPicker.allowedOptions
            if !valid.contains(selectedDuration) {
                let nearest = valid.min(by: { abs($0 - selectedDuration) < abs($1 - selectedDuration) }) ?? 60
                selectedDuration = nearest
            }
        }
    }
}

// MARK: - 4-7-8 Info Modal (same size as Duration; scrollable text inside)
private struct FourSevenEightModal: View {
    @Binding var isPresented: Bool
    @Binding var use478: Bool
    let applyPattern: () -> Void
    let disablePattern: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("4-7-8 Breathing")
                    .lineLimit(1)
                    .truncationMode(.tail)
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
            
            // Scrollable content box
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("A simple pattern to relax the nervous system: inhale through the nose for 4 seconds, hold your breath for 7 seconds, and exhale slowly through the mouth for 8 seconds. Repeat gently without forcing the breath.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.55))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Inhale: 4s", systemImage: "arrow.down.circle")
                            Label("Hold: 7s", systemImage: "pause.circle")
                            Label("Exhale: 8s", systemImage: "arrow.up.circle")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    }
                    .padding(12)
                }
                .frame(maxHeight: 220) // keeps modal compact like Duration
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.96))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                )
            }
            
            // Question + buttons OUTSIDE the scroll area
            Text("Use this method now?")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.45))
                .padding(.top, 6)
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { applyPattern() }
                }) {
                    Text("Yes")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.65, green: 0.8, blue: 0.92))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { disablePattern() }
                }) {
                    Text("No")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.95))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .frame(maxWidth: 340) // same width as Duration modal
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}

// Row that darkens the selected value and fades/downsizes neighbors
private struct WheelRow: View {
    let text: String
    let isSelected: Bool
    let distance: Int   // |index - selectedIndex|

    var body: some View {
        let opacity = max(0.25, 1.0 - 0.22 * Double(distance)) // fade with distance
        let scale: CGFloat = isSelected ? 1.0 : max(0.9, 1.0 - 0.04 * CGFloat(distance))

        return Text(text)
            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4).opacity(opacity))
            .scaleEffect(scale)
            .frame(maxWidth: .infinity, alignment: .center)
            .contentShape(Rectangle())
    }
}

// A reusable wheel picker that drives a Binding<Int> (seconds)
private struct WheelDurationPicker: View {
    @Binding var selectedSeconds: Int

    // Allowed options:
    // 15s, 30s, 45s, 60s; then 2m, 3m, ... 60m
    static let allowedOptions: [Int] = {
        let underMinute = Array(stride(from: 15, through: 60, by: 15))               // 15, 30, 45, 60
        let minutes = Array(stride(from: 120, through: 3600, by: 60))                // 120, 180, ..., 3600
        return underMinute + minutes
    }()

    private let options = WheelDurationPicker.allowedOptions

    var body: some View {
        // Current selection index
        let selectedIndex = options.firstIndex(of: selectedSeconds) ?? 0

        ZStack {
            // Top/bottom fade overlay (soft vignette)
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
                    // Only accept values on our grid
                    if options.contains(newVal) {
                        selectedSeconds = newVal
                    } else {
                        // Snap to nearest valid (defensive)
                        if let nearest = options.min(by: { abs($0 - newVal) < abs($1 - newVal) }) {
                            selectedSeconds = nearest
                        }
                    }
                }
            )) {
                ForEach(options.indices, id: \.self) { i in
                    let secs = options[i]
                    let dist = abs(i - selectedIndex)
                    WheelRow(
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
        if seconds < 60 { return "\(seconds) sec" }        // 15/30/45
        if seconds == 60 { return "1 min" }
        return "\(seconds / 60) min"
    }
}

// MARK: - Stress Level Picker Modal
private struct StressLevelPickerModal: View {
    @Binding var isPresented: Bool
    let title: String
    @Binding var selectedLevel: Int?
    @State private var autoDismissTask: DispatchWorkItem?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with close button
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.black.opacity(0.25))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Compact stress level buttons
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        selectedLevel = level
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("\(level)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(selectedLevel == level ? .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                                .frame(height: 24) // Fixed height for number
                            
                            // Always include label area for consistent alignment
                            Group {
                                if level == 1 {
                                    Text("Calm")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(selectedLevel == level ? .white.opacity(0.9) : Color(red: 0.4, green: 0.5, blue: 0.6))
                                        .frame(height: 20, alignment: .center)
                                } else if level == 5 {
                                    Text("Very\nStressed")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(selectedLevel == level ? .white.opacity(0.9) : Color(red: 0.4, green: 0.5, blue: 0.6))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(minHeight: 20, maxHeight: 24, alignment: .center)
                                } else {
                                    // Invisible placeholder for levels 2-4 to maintain alignment
                                    Text(" ")
                                        .font(.system(size: 10, weight: .medium))
                                        .opacity(0)
                                        .frame(height: 20)
                                }
                            }
                        }
                        .frame(width: 50, height: 65)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedLevel == level ? Color(red: 0.65, green: 0.8, blue: 0.92) : Color.white.opacity(0.8))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 50)
        .onAppear {
            // Auto-dismiss after 5 seconds if not interacted with
            let task = DispatchWorkItem {
                withAnimation(.easeOut(duration: 0.3)) {
                    isPresented = false
                }
            }
            autoDismissTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: task)
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }
}

#Preview {
    BreatheView()
}
