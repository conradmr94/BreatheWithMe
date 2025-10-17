//
//  BreatheView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI
import AVFoundation

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
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    let durations = [30, 60, 120, 300]
    
    init() {
        setupAudioEngine()
    }
    
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
            case .holdIn: return 2.0
            case .exhale: return 4.0
            case .holdOut: return 2.0
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
                                        Image(systemName: "wind.circle")
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
                                .padding(.vertical, 10)
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
                .frame(height: 210)
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
        // Cycle is 12 seconds total: inhale(4s) -> holdIn(2s) -> exhale(4s) -> holdOut(2s)
        let cycleDuration: Double = 12.0
        let timeInCycle = totalElapsedTime.truncatingRemainder(dividingBy: cycleDuration)
        
        let newPhase: BreathingPhase
        if timeInCycle < 4.0 {
            newPhase = .inhale
        } else if timeInCycle < 6.0 {
            newPhase = .holdIn
        } else if timeInCycle < 10.0 {
            newPhase = .exhale
        } else {
            newPhase = .holdOut
        }
        
        // Only update animation when phase actually changes
        if newPhase != currentPhase {
            currentPhase = newPhase
            updateBreathingAnimation()
            playTransitionSound()
        }
    }
    
    func updateBreathingAnimation() {
        switch currentPhase {
        case .inhale:
            withAnimation(.easeInOut(duration: currentPhase.duration)) {
                scale = 1.4
                opacity = 1.0
            }
        case .holdIn:
            // Keep current scale (no animation needed)
            break
        case .exhale:
            withAnimation(.easeInOut(duration: currentPhase.duration)) {
                scale = 0.8
                opacity = 0.6
            }
        case .holdOut:
            // Keep current scale (no animation needed)
            break
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
    
    func setupAudioEngine() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        // Attach player node to engine
        audioEngine.attach(playerNode)
        
        // Connect player to main mixer
        let mainMixer = audioEngine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
        audioEngine.connect(playerNode, to: mainMixer, format: format)
        
        // Prepare and start the engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("✅ Audio engine started for breath transitions")
        } catch {
            print("❌ Failed to start audio engine: \(error)")
        }
    }
    
    func playTransitionSound() {
        // Only play if bell sound is enabled
        guard bellSoundEnabled else { return }
        
        // Generate a soft, gentle gong sound
        let sampleRate: Double = 44100.0
        let duration: Double = 2.0 // Longer for natural gong decay
        let fundamentalFreq: Double = 200.0 // Low, warm frequency
        let volume: Float = 0.12 // Very soft volume
        
        let frameCount = Int(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Gong overtones (inharmonic partials typical of gongs - less harmonic than bells)
        // Format: (frequency multiplier, amplitude, decay rate)
        let partials: [(freq: Double, amp: Double, decay: Double)] = [
            (1.0, 1.0, 0.8),      // Fundamental - slow decay
            (1.6, 0.6, 1.0),      // Inharmonic low
            (2.3, 0.4, 1.2),      // Inharmonic
            (3.1, 0.25, 1.5),     // Inharmonic
            (4.4, 0.15, 2.0),     // Inharmonic high
            (5.8, 0.08, 2.5)      // Very high, quick fade
        ]
        
        // Generate gong sound with soft attack and long decay
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            var sample: Double = 0.0
            
            // Soft attack envelope (gongs don't strike instantly)
            let attackTime = 0.02
            var attackEnvelope: Double = 1.0
            if time < attackTime {
                // Smooth attack
                let t = time / attackTime
                attackEnvelope = t * t * (3.0 - 2.0 * t) // Smooth step function
            }
            
            // Add all partials
            for partial in partials {
                let freq = fundamentalFreq * partial.freq
                let amp = partial.amp
                let decay = partial.decay
                
                // Very gentle exponential decay for each partial
                let decayEnvelope = exp(-decay * time)
                
                // Generate sine wave with attack and decay
                sample += sin(2.0 * .pi * freq * time) * amp * decayEnvelope * attackEnvelope
            }
            
            // Normalize and apply master volume
            channelData[i] = Float(sample) * volume * 0.2 // Very soft
        }
        
        // Play the sound using the audio engine
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        
        // Make sure the player node is playing
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}

#Preview {
    BreatheView()
}

