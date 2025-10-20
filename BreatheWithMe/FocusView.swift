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
}

struct FocusView: View {
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
    
    // Statistics tracking
    @AppStorage("focusStats") private var focusStatsData: Data = Data()
    @State private var sessionStartTime: Date?
    
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
    
    enum PomodoroMode {
        case work, shortBreak, longBreak
        
        var duration: Int {
            switch self {
            case .work: return 1500
            case .shortBreak: return 300
            case .longBreak: return 900
            }
        }
        
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
    
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: currentMode.color.red * 0.3 + 0.7,
                      green: currentMode.color.green * 0.3 + 0.7,
                      blue: currentMode.color.blue * 0.3 + 0.7)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                // Top section with fixed height
                VStack(spacing: 12) {
                    if !isRunning {
                        Text(currentMode.title)
                            .font(.system(size: 34, weight: .light, design: .default))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        Text(currentMode.subtitle)
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 120)
                .padding(.top, 50)
                
                Spacer()
                
                // Main timer circle
                ZStack {
                    // Progress ring
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 12)
                        .frame(width: 280, height: 280)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color(red: currentMode.color.red,
                                  green: currentMode.color.green,
                                  blue: currentMode.color.blue),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: progress)
                    
                    // Center circle
                    Button(action: toggleTimer) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: currentMode.color.red,
                                                  green: currentMode.color.green,
                                                  blue: currentMode.color.blue).opacity(0.9),
                                            Color(red: currentMode.color.red * 0.85,
                                                  green: currentMode.color.green * 0.85,
                                                  blue: currentMode.color.blue * 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 220, height: 220)
                                .shadow(color: Color(red: currentMode.color.red,
                                                     green: currentMode.color.green,
                                                     blue: currentMode.color.blue).opacity(0.3),
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
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(height: 450)
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 24) {
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
                                Text("Focus Sounds")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                            }
                            .foregroundColor(noiseGenerator.isEnabled ? 
                                           Color(red: currentMode.color.red,
                                                 green: currentMode.color.green,
                                                 blue: currentMode.color.blue) :
                                           Color(red: 0.4, green: 0.5, blue: 0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(noiseGenerator.isEnabled ? 
                                          Color(red: currentMode.color.red,
                                                green: currentMode.color.green,
                                                blue: currentMode.color.blue).opacity(0.25) :
                                          Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Noise type selector moved to modal
                        if false {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(NoiseGenerator.NoiseType.allCases, id: \.self) { noiseType in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                noiseGenerator.setNoiseType(noiseType)
                                            }
                                            // Show info message for color noise types
                                            if [.white, .pink, .brown, .blue, .green].contains(noiseType) {
                                                noiseGenerator.showInfoForNoiseType(noiseType)
                                            }
                                        }) {
                                            VStack(spacing: 4) {
                                                Image(systemName: noiseType.icon)
                                                    .font(.system(size: 18))
                                                Text(noiseType.rawValue)
                                                    .font(.system(size: 11, weight: .medium))
                                            }
                                            .foregroundColor(noiseGenerator.selectedNoiseType == noiseType ? 
                                                           .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                                            .frame(width: 60, height: 50)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(noiseGenerator.selectedNoiseType == noiseType ? 
                                                          Color(red: currentMode.color.red,
                                                                green: currentMode.color.green,
                                                                blue: currentMode.color.blue) :
                                                          Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .transition(.opacity)
                    
                    // Control buttons
                    HStack(spacing: 16) {
                        if isRunning {
                            Button(action: resetTimer) {
                                HStack(spacing: 8) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 14))
                                    Text(isAutoCycleMode ? "End Cycle" : "Reset")
                                        .font(.system(size: 16, weight: .regular, design: .default))
                                }
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.7))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            VStack(spacing: 12) {
                                // Auto-cycle toggle
                                Button(action: { 
                                    withAnimation {
                                        isAutoCycleMode.toggle()
                                        if isAutoCycleMode {
                                            cyclePosition = 1
                                            currentMode = .work
                                            timeRemaining = currentMode.duration
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isAutoCycleMode ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 16))
                                        Text("Auto-cycle mode")
                                            .font(.system(size: 15, weight: .medium, design: .default))
                                    }
                                    .foregroundColor(isAutoCycleMode ? 
                                                   Color(red: currentMode.color.red,
                                                         green: currentMode.color.green,
                                                         blue: currentMode.color.blue) :
                                                   Color(red: 0.4, green: 0.5, blue: 0.6))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(isAutoCycleMode ? 
                                                  Color(red: currentMode.color.red,
                                                        green: currentMode.color.green,
                                                        blue: currentMode.color.blue).opacity(0.25) :
                                                  Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Mode selector when not in auto-cycle mode
                                if !isAutoCycleMode {
                                    HStack(spacing: 12) {
                                        Button(action: { selectMode(.work) }) {
                                            Text("Focus")
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(currentMode == .work ? Color.white : Color(red: 0.4, green: 0.5, blue: 0.6))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .fill(currentMode == .work ? 
                                                              Color(red: currentMode.color.red,
                                                                    green: currentMode.color.green,
                                                                    blue: currentMode.color.blue) :
                                                              Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: { selectMode(.shortBreak) }) {
                                            Text("Rest")
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(currentMode == .shortBreak ? Color.white : Color(red: 0.4, green: 0.5, blue: 0.6))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .fill(currentMode == .shortBreak ? 
                                                              Color(red: currentMode.color.red,
                                                                    green: currentMode.color.green,
                                                                    blue: currentMode.color.blue) :
                                                              Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: { selectMode(.longBreak) }) {
                                            Text("Long Rest")
                                                .font(.system(size: 14, weight: .medium, design: .default))
                                                .foregroundColor(currentMode == .longBreak ? Color.white : Color(red: 0.4, green: 0.5, blue: 0.6))
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .fill(currentMode == .longBreak ? 
                                                              Color(red: currentMode.color.red,
                                                                    green: currentMode.color.green,
                                                                    blue: currentMode.color.blue) :
                                                              Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.6))
                                                )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .transition(.opacity)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
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
        .overlay(
            // Info message popup for color noise
            Group {
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
        )
        .overlay(
            Group {
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
                            accentColor: Color(red: currentMode.color.red, green: currentMode.color.green, blue: currentMode.color.blue),
                            isRunning: isRunning
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(2)
                }
            }
        )
        .ignoresSafeArea(.container, edges: .top)
    }
    
    var progress: CGFloat {
        let totalTime = Double(currentMode.duration)
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
        
        // Play start bell
        bellPlayer.playBell()
        
        // Start noise if enabled
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
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
        // Track statistics before resetting
        trackSessionTime()
        
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        sessionStartTime = nil
        
        // Stop noise
        if noiseGenerator.isEnabled {
            noiseGenerator.stopNoise()
        }
        
        if isAutoCycleMode {
            // Reset to beginning of cycle
            cyclePosition = 1
            currentMode = .work
        }
        
        timeRemaining = currentMode.duration
    }
    
    private func trackSessionTime() {
        // Track statistics - always track time, only count as completed if session lasted at least 30 seconds
        if let startTime = sessionStartTime {
            let sessionDuration = Int(Date().timeIntervalSince(startTime))
            if sessionDuration > 0 {
                var stats = focusStats
                
                // Always add time spent
                if currentMode == .work {
                    stats.totalFocusTimeSeconds += sessionDuration
                    // Only count as completed session if it lasted at least 30 seconds
                    if sessionDuration >= 30 {
                        stats.focusSessionsCompleted += 1
                    }
                } else {
                    stats.totalRestTimeSeconds += sessionDuration
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
        
        // Track statistics
        trackSessionTime()
        
        if currentMode == .work {
            completedPomodoros += 1
        }
        
        if isAutoCycleMode {
            // Automatically advance to next phase in cycle
            advanceCycle()
            // Play end bell (end of previous session)
            bellPlayer.playBell()
            // Automatically start the next session
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startTimer()
            }
        } else {
            isRunning = false
            isPaused = false
            // Play end bell
            bellPlayer.playBell()
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
            timeRemaining = currentMode.duration
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
        
        timeRemaining = currentMode.duration
    }
    
    func selectMode(_ mode: PomodoroMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMode = mode
            timeRemaining = mode.duration
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

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Focus Sounds")
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

            Toggle(isOn: Binding(
                get: { noiseGenerator.isEnabled },
                set: { value in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        noiseGenerator.isEnabled = value
                    }
                    if value {
                        if isRunning { noiseGenerator.startNoise() }
                    } else {
                        if isRunning { noiseGenerator.stopNoise() }
                    }
                }
            )) {
                Text("Enable Focus Sounds")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
            }
            .toggleStyle(SwitchToggleStyle(tint: accentColor))

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
                                    .fill(noiseGenerator.selectedNoiseType == noiseType ? accentColor : Color.white.opacity(0.95))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxHeight: 260)
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

#Preview {
    FocusView()
}

