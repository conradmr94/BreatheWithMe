//
//  SleepView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.


import SwiftUI

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
    
    var body: some View {
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
        .ignoresSafeArea(.container, edges: .top)
        .preferredColorScheme(.dark)
        .swipeDownToOpenProfile {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showProfile = true }
        }
        .topSlideCover(isPresented: $showProfile) {
            ProfileView(onDismiss: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { showProfile = false }
            })
            .preferredColorScheme(.light)
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view.toolbar(showProfile ? .hidden : .visible, for: .tabBar)
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
                        SleepNoiseOptionsModal(
                            isPresented: $showNoiseSettings,
                            noiseGenerator: noiseGenerator,
                            isRunning: isRunning
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(2)
                }
            }
        )
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
        startPulseAnimation()
        
        // Start noise if enabled
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Track sleep session if it was at least 60 seconds (1 minute)
        if let startTime = sessionStartTime, elapsedSeconds >= 60 {
            let sessionDuration = Int(Date().timeIntervalSince(startTime))
            
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
            HStack {
                Text("Sleep Sounds")
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
                Text("Enable Sleep Sounds")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.5, blue: 0.8)))

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
    SleepView()
}
