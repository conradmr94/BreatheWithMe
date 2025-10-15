//
//  ContentView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isBreathing = false
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var remainingTime: Int = 0
    @State private var selectedDuration: Int = 60
    @State private var timer: Timer?
    @State private var showSettings = false
    
    let durations = [30, 60, 120, 300]
    
    enum BreathingPhase {
        case inhale, holdIn, exhale, holdOut
        
        var text: String {
            switch self {
            case .inhale: return "Breathe In"
            case .holdIn: return "Hold"
            case .exhale: return "Breathe Out"
            case .holdOut: return "Hold"
            }
        }
        
        var duration: Double {
            switch self {
            case .inhale: return 4.0
            case .holdIn: return 4.0
            case .exhale: return 4.0
            case .holdOut: return 4.0
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
                // Top section
                if !isBreathing {
                    VStack(spacing: 12) {
                        Text("Breathe")
                            .font(.system(size: 34, weight: .light, design: .default))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            .padding(.top, 70)
                        
                        Text("Find your calm")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
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
                                isBreathing ? .easeInOut(duration: currentPhase.duration) : .easeInOut(duration: 0.5),
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
                                    isBreathing ? .easeInOut(duration: currentPhase.duration) : .easeInOut(duration: 0.5),
                                    value: scale
                                )
                            
                            // Inner circle
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 180, height: 180)
                                .scaleEffect(isBreathing ? scale : 1.0)
                                .animation(
                                    isBreathing ? .easeInOut(duration: currentPhase.duration) : .easeInOut(duration: 0.5),
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
                                        Text("START")
                                            .font(.system(size: 18, weight: .medium, design: .default))
                                            .foregroundColor(.white)
                                            .tracking(2)
                                        
                                        Image(systemName: "play.circle")
                                            .font(.system(size: 36, weight: .thin))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
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
                        VStack(spacing: 16) {
                            Text("DURATION")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .tracking(1.5)
                            
                            HStack(spacing: 12) {
                                ForEach(durations, id: \.self) { duration in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDuration = duration
                                        }
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(formatDuration(duration))
                                                .font(.system(size: 22, weight: .light, design: .default))
                                            Text(duration < 60 ? "sec" : "min")
                                                .font(.system(size: 11, weight: .regular, design: .default))
                                        }
                                        .frame(width: 75, height: 75)
                                        .background(
                                            RoundedRectangle(cornerRadius: 38)
                                                .fill(selectedDuration == duration ? 
                                                      Color(red: 0.65, green: 0.8, blue: 0.92) : 
                                                      Color.white.opacity(0.5))
                                        )
                                        .foregroundColor(
                                            selectedDuration == duration ?
                                            .white : Color(red: 0.4, green: 0.5, blue: 0.6)
                                        )
                                        .shadow(color: selectedDuration == duration ? 
                                                Color(red: 0.5, green: 0.65, blue: 0.8).opacity(0.3) : 
                                                Color.clear, 
                                                radius: 10, x: 0, y: 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
    
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
        currentPhase = .inhale
        animateBreathing()
        
        // Timer for countdown
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopBreathing()
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
    }
    
    func animateBreathing() {
        guard isBreathing else { return }
        
        switch currentPhase {
        case .inhale:
            scale = 1.4
            opacity = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + currentPhase.duration) {
                if self.isBreathing {
                    self.currentPhase = .holdIn
                    self.animateBreathing()
                }
            }
            
        case .holdIn:
            // Keep current scale
            DispatchQueue.main.asyncAfter(deadline: .now() + currentPhase.duration) {
                if self.isBreathing {
                    self.currentPhase = .exhale
                    self.animateBreathing()
                }
            }
            
        case .exhale:
            scale = 0.8
            opacity = 0.6
            DispatchQueue.main.asyncAfter(deadline: .now() + currentPhase.duration) {
                if self.isBreathing {
                    self.currentPhase = .holdOut
                    self.animateBreathing()
                }
            }
            
        case .holdOut:
            // Keep current scale
            DispatchQueue.main.asyncAfter(deadline: .now() + currentPhase.duration) {
                if self.isBreathing {
                    self.currentPhase = .inhale
                    self.animateBreathing()
                }
            }
        }
    }
    
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
}

#Preview {
    ContentView()
}

