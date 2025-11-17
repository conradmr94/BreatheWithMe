//
//  WalkView.swift
//  BreatheWithMe
//
//  A green-accented hub for mindful walks with quick actions for insights,
//  sounds, and sessions. Styled to mirror FocusView.
//

import SwiftUI
import UIKit
import MapKit

struct WalkView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showProfile = false
    @State private var highlightedAction: WalkAction?
    @State private var showNoiseSettings = false
    @StateObject private var noiseGenerator = NoiseGenerator()
    @StateObject private var walkSessionManager = WalkSessionManager.shared
    @State private var isWalking = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showSessionDetails = false
    @State private var selectedBreathingPattern = "Box"
    @State private var showInsightsModal = false
    @State private var elapsedSeconds: Int = 0
    @State private var walkTimer: Timer?

    private enum WalkAction {
        case insights, sounds, session
    }

    private let accentColor = Color(red: 0.32, green: 0.72, blue: 0.55)

    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }

    private var usesDarkAppearance: Bool {
        themeManager.colorScheme(for: systemColorScheme) == .dark
    }

    private var controlSurfaceColor: Color {
        usesDarkAppearance ? themeColors.cardBackground.opacity(0.72) : themeColors.cardBackground.opacity(0.96)
    }

    private var controlBorderColor: Color {
        usesDarkAppearance ? Color.white.opacity(0.18) : themeColors.separator.opacity(0.82)
    }

    private var backgroundGradient: some View {
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

    private func functionalButtonBackground(
        isActive: Bool,
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

    private var topTitleSection: some View {
        VStack(spacing: 12) {
            Text("Walk")
                .font(.system(size: 34, weight: .light, design: .default))
                .foregroundColor(themeColors.primaryText)
                .transition(.opacity.combined(with: .move(edge: .top)))

            Text("Mindful steps with fresh air")
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(themeColors.secondaryText)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 120)
        .padding(.top, 50)
    }

    private func actionButton(
        _ action: WalkAction,
        icon: String,
        title: String,
        subtitle: String? = nil,
        isWide: Bool = false
    ) -> some View {
        let isActive = highlightedAction == action
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                highlightedAction = action
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeColors.secondaryText)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.85)
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, isWide ? 22 : 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                functionalButtonBackground(
                    isActive: isActive,
                    usesAccentFillWhenInactive: isWide,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var soundsButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNoiseSettings = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: noiseGenerator.isEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                    .font(.system(size: 16))
                Text("Sounds")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                functionalButtonBackground(
                    isActive: noiseGenerator.isEnabled,
                    usesAccentFillWhenInactive: false,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var quickActionsSection: some View {
        GeometryReader { proxy in
            let buttonWidth = (proxy.size.width - 12) / 2
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    insightsButton
                    soundsButton
                }
                HStack {
                    Spacer()
                    sessionButton
                        .frame(width: buttonWidth)
                    Spacer()
                }
            }
        }
        .frame(height: 155)
        .padding(.horizontal, 20)
    }
    
    private var startButtonSection: some View {
        Button(action: toggleWalk) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.9),
                                accentColor.opacity(0.65)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .shadow(color: accentColor.opacity(0.3), radius: 30, x: 0, y: 10)
                
                VStack(spacing: 12) {
                    if isWalking {
                        Text(sessionDurationText)
                            .font(.system(size: 52, weight: .thin, design: .default))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        Text("WALK")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.white.opacity(0.85))
                            .tracking(1.5)
                    } else {
                        Image(systemName: "figure.walk.motion")
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
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 12)
        .frame(height: 450)
    }
    
    private var insightsButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.18)) {
                highlightedAction = .insights
                showInsightsModal = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                Text("Insights")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                functionalButtonBackground(
                    isActive: highlightedAction == .insights,
                    usesAccentFillWhenInactive: false,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sessionButton: some View {
        Button(action: { showSessionDetails = true }) {
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Session")
                    .font(.system(size: 15, weight: .medium))
                Spacer()
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                functionalButtonBackground(
                    isActive: isWalking,
                    usesAccentFillWhenInactive: true,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    private func toggleWalk() {
        if isWalking {
            completeWalkSession()
        } else {
            startWalkSession()
        }
    }
    
    private func startWalkSession() {
        walkSessionManager.startWalk()
        elapsedSeconds = 0
        walkTimer?.invalidate()
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isWalking = true
        }
    }
    
    private func completeWalkSession() {
        if noiseGenerator.isEnabled {
            noiseGenerator.fadeOut()
        }
        walkSessionManager.completeWalk()
        walkTimer?.invalidate()
        walkTimer = nil
        elapsedSeconds = 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isWalking = false
        }
    }
    
    private var sessionDurationText: String {
        let seconds = max(0, elapsedSeconds)
        let minutes = seconds / 60
        let remaining = seconds % 60
        return String(format: "%02d:%02d", minutes, remaining)
    }
    
    private var stepsText: String { "—" }
    
    private var distanceText: String {
        String(format: "%.2f km", currentDistanceMeters / 1000.0)
    }
    
    private var paceText: String {
        let distanceKm = currentDistanceMeters / 1000.0
        guard distanceKm > 0 else { return "—" }
        let secondsPerKm = Double(max(1, elapsedSeconds)) / distanceKm
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private var caloriesText: String {
        currentCalories > 0 ? String(format: "%.0f kcal", currentCalories) : "— kcal"
    }
    
    private var stressText: String { "—" }
    
    private var currentDistanceMeters: Double {
        // Placeholder until live distance is wired in
        0
    }
    
    private var currentCalories: Double {
        // Placeholder until calorie estimation is wired in
        0
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
                    .padding(.bottom, 80)
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
                    accentColor: accentColor,
                    isRunning: isWalking,
                    title: "Walk Sounds"
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(2)
        }
    }
    
    @ViewBuilder
    private var insightsOverlay: some View {
        if showInsightsModal {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showInsightsModal = false
                        }
                    }
                WalkInsightsModal(
                    isPresented: $showInsightsModal,
                    accentColor: accentColor,
                    stepsText: stepsText,
                    distanceText: distanceText,
                    timeText: sessionDurationText,
                    paceText: paceText,
                    caloriesText: caloriesText,
                    stressText: stressText
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
                
                startButtonSection
                
                Spacer()
                
                VStack(spacing: 16) {
                    quickActionsSection
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
                view.toolbar(showProfile ? .hidden : .visible, for: .tabBar)
            } else {
                view
            }
        }
        .overlay(infoMessageOverlay)
        .overlay(noiseSettingsOverlay)
        .overlay(insightsOverlay)
        .sheet(isPresented: $showSessionDetails) {
            SessionDetailsModal(
                isPresented: $showSessionDetails,
                mapRegion: $mapRegion,
                isWalking: isWalking,
                durationText: sessionDurationText,
                distanceMeters: currentDistanceMeters,
                calories: currentCalories,
                accentColor: accentColor,
                selectedPattern: $selectedBreathingPattern
            )
        }
        .onChange(of: showNoiseSettings) { isPresented in
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": isPresented]
            )
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": false]
            )
            walkTimer?.invalidate()
            walkTimer = nil
        }
    }
}

#Preview {
    WalkView()
        .environmentObject(AppThemeManager())
}

// MARK: - Session Details Modal
private struct SessionDetailsModal: View {
    @Binding var isPresented: Bool
    @Binding var mapRegion: MKCoordinateRegion
    let isWalking: Bool
    let durationText: String
    let distanceMeters: Double
    let calories: Double
    let accentColor: Color
    @Binding var selectedPattern: String
    
    private var distanceText: String {
        String(format: "%.2f km", distanceMeters / 1000.0)
    }
    
    private var caloriesText: String {
        calories > 0 ? String(format: "%.0f kcal", calories) : "— kcal"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Map(coordinateRegion: $mapRegion)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
                
                VStack(spacing: 14) {
                    infoRow(title: "Status", value: isWalking ? "In progress" : "Not running")
                    infoRow(title: "Duration", value: durationText)
                    infoRow(title: "Distance", value: distanceText)
                    infoRow(title: "Calories", value: caloriesText)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Breathing Patterns")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.primary)

                    BreathingPatternPicker(
                        patterns: ["Box", "4-7-8", "Equal Breath", "Resonant 5.5"],
                        selectedPattern: $selectedPattern,
                        accentColor: accentColor
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                        .foregroundColor(accentColor)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.primary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.secondary)
        }
    }
}

// MARK: - Breathing Pattern Picker
private struct BreathingPatternPicker: View {
    let patterns: [String]
    @Binding var selectedPattern: String
    let accentColor: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(patterns, id: \.self) { pattern in
                Button(action: {
                    selectedPattern = pattern
                }) {
                    HStack {
                        Text(pattern)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(selectedPattern == pattern ? .white : Color.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPattern == pattern ? accentColor : Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPattern == pattern ? accentColor : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Walk Insights Modal
private struct WalkInsightsModal: View {
    @Binding var isPresented: Bool
    let accentColor: Color
    let stepsText: String
    let distanceText: String
    let timeText: String
    let paceText: String
    let caloriesText: String
    let stressText: String
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        let modalWidth: CGFloat = 400
        let modalHeight: CGFloat = 520
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Button(action: { withAnimation { isPresented = false } }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                insightTile(title: "Steps", value: stepsText, icon: "figure.walk")
                insightTile(title: "Distance", value: distanceText, icon: "location")
                insightTile(title: "Time", value: timeText, icon: "clock")
                insightTile(title: "Pace", value: paceText, icon: "speedometer")
                insightTile(title: "Calories", value: caloriesText, icon: "flame")
                insightTile(title: "Stress Relief", value: stressText, icon: "heart.text.square")
            }
            
            Spacer()
            
            Button(action: {
                withAnimation { isPresented = false }
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
    }
    
    private func insightTile(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
            }
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
}
