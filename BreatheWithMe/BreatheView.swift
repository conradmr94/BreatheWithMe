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
}

struct BreatheView: View {
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
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.93, blue: 0.98)
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
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            .transition(.opacity .combined(with: .move(edge: .top)))
                        
                        Text("Find your calm")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
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
                                            Color(red: 0.65, green: 0.8, blue: 0.92),
                                            Color(red: 0.55, green: 0.72, blue: 0.88)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 220, height: 220)
                                .scaleEffect(isBreathing ? scale : 1.0)
                                .shadow(color: Color(red: 0.5, green: 0.65, blue: 0.8).opacity(0.3), radius: 30, x: 0, y: 10)
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
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            
                            Button(action: stopBreathing) {
                                Text("Stop")
                                    .font(.system(size: 16, weight: .regular, design: .default))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white.opacity(0.6))
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
                                .foregroundColor(bellSoundEnabled ?
                                                 Color(red: 0.65, green: 0.8, blue: 0.92) :
                                                 Color(red: 0.4, green: 0.5, blue: 0.6))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(bellSoundEnabled ?
                                              Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.25) :
                                              Color.white.opacity(0.6))
                                )
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
                                            Text("DURATION")
                                            if use478 {
                                                // subtle badge indicating 4-7-8 is active (affects phases, not duration)
                                                Text("4-7-8")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 3)
                                                    .background(
                                                        Capsule().fill(Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.25))
                                                    )
                                            }
                                        }
                                        .font(.system(size: 13, weight: .medium, design: .default))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                        .tracking(1.5)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.6))
                                        )
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
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(use478 ? .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                                        .tracking(1.0)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(use478 ? Color(red: 0.65, green: 0.8, blue: 0.92) : Color.white.opacity(0.95))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                        )
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
        .preferredColorScheme(.light)
        .swipeDownToOpenProfile {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                showProfile = true
            }
        }
        .topSlideCover(isPresented: $showProfile) {
            ProfileView(onDismiss: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    showProfile = false
                }
            })
            .preferredColorScheme(.light)
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
            }
        )
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
        isBreathing = true
        remainingTime = selectedDuration
        totalElapsedTime = 0
        currentPhase = .inhale
        sessionStartTime = Date()
        
        updateBreathingAnimation()
        if bellSoundEnabled { bellPlayer.playBell() }
        
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
        if let startTime = sessionStartTime {
            let sessionDuration = Int(Date().timeIntervalSince(startTime))
            if sessionDuration > 0 {
                var stats = breatheStats
                
                // Always add time spent
                stats.totalTimeSeconds += sessionDuration
                
                // Only count as completed session if it lasted at least 10 seconds
                if sessionDuration >= 10 {
                    stats.sessionsCompleted += 1
                }
                
                // Update the stored data directly
                if let encoded = try? JSONEncoder().encode(stats) {
                    breatheStatsData = encoded
                }
            }
        }
        
        totalElapsedTime = 0
        sessionStartTime = nil
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

#Preview {
    BreatheView()
}
