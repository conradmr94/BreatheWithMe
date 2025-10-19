//
//  BreatheView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

struct BreatheView: View {
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
    
    let durations = [30, 60, 120, 300]
    
    // default init
    
    enum BreathingPhase {
        case inhale, exhale
        
        var text: String {
            switch self {
            case .inhale: return "Breathe In"
            case .exhale: return "Breathe Out"
            }
        }
        
        var duration: Double {
            switch self {
            case .inhale: return 4.0
            case .exhale: return 4.0
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
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        Text("Find your calm")
                            .font(.system(size: 16, weight: .regular, design: .default))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(height: 120)
                .padding(.top, 30)
                
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
                                isBreathing ? .easeInOut(duration: breathInterval) : .easeInOut(duration: 0.5),
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
                                    isBreathing ? .easeInOut(duration: breathInterval) : .easeInOut(duration: 0.5),
                                    value: scale
                                )
                            
                            // Inner circle
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 180, height: 180)
                                .scaleEffect(isBreathing ? scale : 1.0)
                                .animation(
                                    isBreathing ? .easeInOut(duration: breathInterval) : .easeInOut(duration: 0.5),
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
                                        
                                        if isAdjustingInterval {
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
                                    guard !isBreathing else { return }
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
                                    }
                                    lastDragAngle = angle
                                }
                                .onEnded { _ in
                                    lastDragAngle = nil
                                    isAdjustingInterval = false
                                }
                        )
                        .allowsHitTesting(!isBreathing)
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
                        VStack(spacing: 8) {
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
                            
                            Text("DURATION")
                                .font(.system(size: 13, weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .tracking(1.5)
                                .padding(.top, 4)
                            
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
                .frame(height: 155)
                .padding(.bottom, 60)
            }
        }
        .preferredColorScheme(.light)
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
        totalElapsedTime = 0
        currentPhase = .inhale
        
        // Trigger the initial animation immediately
        updateBreathingAnimation()
        if bellSoundEnabled { bellPlayer.playBell() }
        
        // Timer updates at 0.1 second intervals for smooth phase transitions
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.totalElapsedTime += 0.1
            
            // Update the breathing phase based on cycle position
            self.updateCurrentPhase()
            
            // Update remaining time (calculate as whole seconds)
            let newRemainingTime = max(0, self.selectedDuration - Int(self.totalElapsedTime))
            if newRemainingTime != self.remainingTime {
                self.remainingTime = newRemainingTime
            }
            
            // Stop when time runs out
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
        totalElapsedTime = 0
    }
    
    func updateCurrentPhase() {
        // Calculate position within the breathing cycle
        // Dynamic cycle: inhale(breathInterval) -> exhale(breathInterval)
        let cycleDuration: Double = breathInterval * 2.0
        let timeInCycle = totalElapsedTime.truncatingRemainder(dividingBy: cycleDuration)
        
        let newPhase: BreathingPhase
        if timeInCycle < breathInterval {
            newPhase = .inhale
        } else {
            newPhase = .exhale
        }
        
        // Only update animation when phase actually changes
        if newPhase != currentPhase {
            currentPhase = newPhase
            updateBreathingAnimation()
            if bellSoundEnabled { bellPlayer.playBell() }
        }
    }
    
    func updateBreathingAnimation() {
        switch currentPhase {
        case .inhale:
            withAnimation(.easeInOut(duration: breathInterval)) {
                scale = 1.4
                opacity = 1.0
            }
        case .exhale:
            withAnimation(.easeInOut(duration: breathInterval)) {
                scale = 0.8
                opacity = 0.6
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
    
    func formatIntervalNumber(_ seconds: Double) -> String {
        let rounded = (seconds * 10).rounded() / 10
        if abs(rounded.rounded() - rounded) < 0.0001 {
            return "\(Int(rounded))"
        } else {
            return String(format: "%.1f", rounded)
        }
    }
    
    // sound is provided by BellPlayer
}

#Preview {
    BreatheView()
}

