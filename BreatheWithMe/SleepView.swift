//
//  SleepView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

struct SleepView: View {
    @State private var showProfile: Bool = false
    @State private var isRunning = false
    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    
    // Removed SLEEP TIMER controls
    
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
                ForEach(0..<20, id: \.self) { index in
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
                // Top section with fixed height
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
                            // Main moon
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
                            Circle()
                                .fill(Color(red: 0.7, green: 0.72, blue: 0.8).opacity(0.3))
                                .frame(width: 30, height: 30)
                                .offset(x: -40, y: -20)
                            
                            Circle()
                                .fill(Color(red: 0.7, green: 0.72, blue: 0.8).opacity(0.2))
                                .frame(width: 20, height: 20)
                                .offset(x: 30, y: 15)
                            
                            Circle()
                                .fill(Color(red: 0.7, green: 0.72, blue: 0.8).opacity(0.25))
                                .frame(width: 25, height: 25)
                                .offset(x: 10, y: -35)
                            
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
                    if isRunning {
                        startPulseAnimation()
                    }
                }
                
                Spacer()
                
                // Bottom section
                VStack(spacing: 24) {
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
    }
    
    func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    func startTimer() {
        isRunning = true
        elapsedSeconds = 0
        startPulseAnimation()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
        pulseScale = 1.0
    }
    
    func startPulseAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.08
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    SleepView()
}

