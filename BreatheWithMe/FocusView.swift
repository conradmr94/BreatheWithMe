//
//  FocusView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

struct FocusView: View {
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var timeRemaining: Int = 1500
    @State private var currentMode: PomodoroMode = .work
    @State private var completedPomodoros: Int = 0
    @State private var timer: Timer?
    @State private var cyclePosition: Int = 1 // Position in the 1-8 cycle
    @State private var isAutoCycleMode: Bool = true
    
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
    
    var body: some View {
        ZStack {
            // Gradient background based on mode
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
                .frame(height: 120)
                .padding(.top, 30)
                
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
                                            Text("Work")
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
                                            Text("Break")
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
                                            Text("Long Break")
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
                .frame(height: 155)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.light)
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
    }
    
    func resumeTimer() {
        isPaused = false
        startTimer()
    }
    
    func resetTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        
        if isAutoCycleMode {
            // Reset to beginning of cycle
            cyclePosition = 1
            currentMode = .work
        }
        
        timeRemaining = currentMode.duration
    }
    
    func completeSession() {
        timer?.invalidate()
        timer = nil
        
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

#Preview {
    FocusView()
}

