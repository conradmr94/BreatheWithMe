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
import HealthKit

struct WalkView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showProfile = false
    @State private var highlightedAction: WalkAction?
    @State private var showNoiseSettings = false
    @StateObject private var noiseGenerator = NoiseGenerator()
    @StateObject private var walkSessionManager = WalkSessionManager.shared
    @StateObject private var locationManager = WalkLocationManager()
    @State private var isWalking = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180)
    )
    @State private var showSessionDetails = false
    @State private var selectedBreathingPattern = "Box"
    @State private var showInsightsModal = false
    @State private var elapsedSeconds: Int = 0
    @State private var walkTimer: Timer?
    @State private var currentSteps: Int = 0
    @State private var currentCalories: Double = 0
    @State private var sessionStartSteps: Int = 0
    @State private var breathingEnabled = false
    @State private var bellSoundEnabled = true
    @State private var currentBreathingPhase: BreathingPhase = .inhale
    private let bellPlayer = BellPlayer()

    private enum WalkAction {
        case insights, sounds, session
    }
    
    private enum BreathingPhase {
        case inhale, hold, exhale, holdAfterExhale
        
        var text: String {
            switch self {
            case .inhale: return "Breathe In"
            case .hold, .holdAfterExhale: return "Hold"
            case .exhale: return "Breathe Out"
            }
        }
    }

    private let accentColor = Color(red: 0.32, green: 0.72, blue: 0.55)
    
    private var locationId: String {
        guard let location = locationManager.userLocation else { return "" }
        return "\(location.latitude),\(location.longitude)"
    }

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
                        if breathingEnabled {
                            Text(currentBreathingPhase.text.uppercased())
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .tracking(2)
                        }
                        
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
        // Start location tracking
        locationManager.startTracking()
        
        // Get initial step count
        Task {
            sessionStartSteps = await fetchCurrentSteps()
            currentSteps = 0
        }
        
        // Start session tracking
        walkSessionManager.startWalk()
        elapsedSeconds = 0
        
        // Start timer for duration and periodic updates
        walkTimer?.invalidate()
        walkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
            
            // Update breathing phase if enabled (synchronized with walk timer)
            if breathingEnabled {
                updateBreathingPhase()
            }
            
            // Update steps and calories every 5 seconds
            if elapsedSeconds % 5 == 0 {
                Task {
                    await updateWalkMetrics()
                }
            }
        }
        
        if noiseGenerator.isEnabled {
            noiseGenerator.startNoise()
        }
        
        // Start breathing guidance if enabled
        if breathingEnabled {
            startBreathingGuidance()
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            isWalking = true
        }
    }
    
    private func completeWalkSession() {
        // Stop location tracking
        locationManager.stopTracking()
        
        // Stop sound
        if noiseGenerator.isEnabled {
            noiseGenerator.fadeOut()
        }
        
        // Stop breathing guidance
        stopBreathingGuidance()
        
        // Final metrics update
        Task {
            await updateWalkMetrics()
            
            // Save session with all metrics
            let finalSteps = currentSteps > 0 ? currentSteps : nil
            let finalDistance = locationManager.totalDistanceMeters > 0 ? locationManager.totalDistanceMeters : nil
            let finalCalories = currentCalories > 0 ? currentCalories : nil
            let routeData = locationManager.route.isEmpty ? nil : locationManager.route.map { 
                EnhancedSession.Coordinate(latitude: $0.latitude, longitude: $0.longitude) 
            }
            
            walkSessionManager.completeWalk(
                steps: finalSteps,
                distanceMeters: finalDistance,
                caloriesBurned: finalCalories,
                stressReliefScore: nil,
                contentId: noiseGenerator.isEnabled ? noiseGenerator.selectedNoiseType.rawValue : nil,
                contentDuration: elapsedSeconds,
                route: routeData
            )
        }
        
        // Reset UI state
        walkTimer?.invalidate()
        walkTimer = nil
        elapsedSeconds = 0
        currentSteps = 0
        currentCalories = 0
        sessionStartSteps = 0
        
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
    
    private var stepsText: String {
        currentSteps > 0 ? "\(currentSteps)" : "—"
    }
    
    private var distanceText: String {
        let distance = locationManager.totalDistanceKilometers
        return distance > 0 ? String(format: "%.2f km", distance) : "— km"
    }
    
    private var paceText: String {
        let distanceKm = locationManager.totalDistanceKilometers
        guard distanceKm > 0, elapsedSeconds > 0 else { return "—" }
        let secondsPerKm = Double(elapsedSeconds) / distanceKm
        let minutes = Int(secondsPerKm) / 60
        let seconds = Int(secondsPerKm) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private var caloriesText: String {
        currentCalories > 0 ? String(format: "%.0f kcal", currentCalories) : "— kcal"
    }
    
    private var stressText: String { "—" }
    
    private var currentDistanceMeters: Double {
        locationManager.totalDistanceMeters
    }
    
    // MARK: - Breathing Pattern Support
    
    private func getPatternTimings(_ pattern: String) -> [Double] {
        switch pattern {
        case "Box":
            // 4s inhale, 4s hold, 4s exhale, 4s hold
            return [4.0, 4.0, 4.0, 4.0]
        case "4-7-8":
            // 4s inhale, 7s hold, 8s exhale
            return [4.0, 7.0, 8.0]
        case "Equal Breath":
            // 4s inhale, 4s exhale (no holds)
            return [4.0, 0.0, 4.0]
        case "Resonant 5.5":
            // 5.5s inhale, 5.5s exhale (no holds)
            return [5.5, 0.0, 5.5]
        default:
            return [4.0, 0.0, 4.0]
        }
    }
    
    private func getCycleDuration(_ pattern: String) -> Double {
        let timings = getPatternTimings(pattern)
        return timings.reduce(0, +)
    }
    
    private func startBreathingGuidance() {
        guard breathingEnabled else { return }
        
        currentBreathingPhase = .inhale
        
        // Play initial bell
        if bellSoundEnabled {
            bellPlayer.playBell()
        }
    }
    
    private func stopBreathingGuidance() {
        currentBreathingPhase = .inhale
    }
    
    private func updateBreathingPhase() {
        guard breathingEnabled else { return }
        
        let timings = getPatternTimings(selectedBreathingPattern)
        let cycleDuration = getCycleDuration(selectedBreathingPattern)
        let t = Double(elapsedSeconds).truncatingRemainder(dividingBy: cycleDuration)
        
        let newPhase: BreathingPhase
        
        if timings.count == 4 {
            // Box breathing: inhale, hold, exhale, hold
            if t < timings[0] {
                newPhase = .inhale
            } else if t < timings[0] + timings[1] {
                newPhase = .hold
            } else if t < timings[0] + timings[1] + timings[2] {
                newPhase = .exhale
            } else {
                newPhase = .holdAfterExhale
            }
        } else {
            // 3-phase patterns: inhale, hold (if any), exhale
            if t < timings[0] {
                newPhase = .inhale
            } else if timings[1] > 0 && t < timings[0] + timings[1] {
                newPhase = .hold
            } else {
                newPhase = .exhale
            }
        }
        
        // Play bell on phase change
        if newPhase != currentBreathingPhase {
            currentBreathingPhase = newPhase
            if bellSoundEnabled {
                bellPlayer.playBell()
            }
        }
    }
    
    // MARK: - HealthKit Integration
    
    private func fetchCurrentSteps() async -> Int {
        let healthStore = HKHealthStore()
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }
    
    private func updateWalkMetrics() async {
        // Get current total steps and calculate difference
        let totalStepsNow = await fetchCurrentSteps()
        currentSteps = max(0, totalStepsNow - sessionStartSteps)
        
        // Estimate calories (rough calculation: 0.04 calories per step for average person)
        // Plus additional calories from distance if we have GPS data
        let stepCalories = Double(currentSteps) * 0.04
        
        // If we have distance data, use a more accurate MET-based calculation
        let distanceKm = locationManager.totalDistanceKilometers
        if distanceKm > 0 && elapsedSeconds > 0 {
            // Average walking MET value = 3.5
            // Calories = MET × weight(kg) × time(hours)
            // Assuming average weight of 70kg
            let hours = Double(elapsedSeconds) / 3600.0
            let metCalories = 3.5 * 70.0 * hours
            currentCalories = metCalories
        } else {
            currentCalories = stepCalories
        }
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
                route: locationManager.route,
                userLocation: locationManager.userLocation,
                isWalking: isWalking,
                durationText: sessionDurationText,
                distanceMeters: currentDistanceMeters,
                calories: currentCalories,
                accentColor: accentColor,
                selectedPattern: $selectedBreathingPattern,
                breathingEnabled: $breathingEnabled,
                bellSoundEnabled: $bellSoundEnabled,
                onBreathingToggled: {
                    // Restart breathing guidance with new settings if walking
                    if isWalking && breathingEnabled {
                        // Reset to inhale phase and play bell
                        currentBreathingPhase = .inhale
                        if bellSoundEnabled {
                            bellPlayer.playBell()
                        }
                    }
                }
            )
        }
        .onChange(of: showNoiseSettings) { isPresented in
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": isPresented]
            )
        }
        .onChange(of: locationId) { _ in
            if let location = locationManager.userLocation {
                // Update map region to follow user
                mapRegion = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        .onAppear {
            // Request location authorization when view appears
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestAuthorization()
            } else if locationManager.authorizationStatus == .authorizedWhenInUse ||
                      locationManager.authorizationStatus == .authorizedAlways {
                // If already authorized, start monitoring location to get current position
                locationManager.startMonitoringLocation()
            }
            
            // Update map to user's current location if available
            if let location = locationManager.userLocation {
                mapRegion = MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": false]
            )
            walkTimer?.invalidate()
            walkTimer = nil
            
            // Stop location monitoring if not actively tracking a walk
            if !isWalking {
                locationManager.stopMonitoringLocation()
            }
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
    let route: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?
    let isWalking: Bool
    let durationText: String
    let distanceMeters: Double
    let calories: Double
    let accentColor: Color
    @Binding var selectedPattern: String
    @State private var showBreathingPatterns = false
    @Binding var breathingEnabled: Bool
    @Binding var bellSoundEnabled: Bool
    var onBreathingToggled: () -> Void
    
    private var distanceText: String {
        distanceMeters > 0 ? String(format: "%.2f km", distanceMeters / 1000.0) : "— km"
    }
    
    private var caloriesText: String {
        calories > 0 ? String(format: "%.0f kcal", calories) : "— kcal"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    WalkMapView(
                        region: $mapRegion,
                        route: route,
                        userLocation: userLocation,
                        accentColor: accentColor
                    )
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

                        if !showBreathingPatterns {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Enhance your walk with guided breathing patterns. They can help you stay present, reduce stress, and maximize the mindfulness benefits of your walk.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("Would you like to use this feature?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.primary)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showBreathingPatterns = true
                                            breathingEnabled = true
                                            if isWalking {
                                                onBreathingToggled()
                                            }
                                        }
                                    }) {
                                        Text("Yes")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(accentColor)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        breathingEnabled = false
                                        isPresented = false
                                    }) {
                                        Text("Maybe Later")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.secondarySystemBackground))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        } else {
                            VStack(spacing: 14) {
                                BreathingPatternPickerWithDescriptions(
                                    selectedPattern: $selectedPattern,
                                    accentColor: accentColor,
                                    onPatternChanged: {
                                        if isWalking {
                                            onBreathingToggled()
                                        }
                                    }
                                )
                                
                                // Bell sound toggle
                                HStack {
                                    Toggle(isOn: $bellSoundEnabled) {
                                        HStack(spacing: 8) {
                                            Image(systemName: bellSoundEnabled ? "bell.fill" : "bell.slash")
                                                .font(.system(size: 14))
                                                .foregroundColor(accentColor)
                                            Text("Transition Sounds")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Color.primary)
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: accentColor))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                
                                // Disable breathing button
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        breathingEnabled = false
                                        showBreathingPatterns = false
                                        if isWalking {
                                            onBreathingToggled()
                                        }
                                    }
                                }) {
                                    Text("Disable Breathing Guidance")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                    )
                }
                .padding()
            }
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

// MARK: - Breathing Pattern Picker with Descriptions
private struct BreathingPatternPickerWithDescriptions: View {
    @Binding var selectedPattern: String
    let accentColor: Color
    var onPatternChanged: (() -> Void)? = nil
    
    private let patterns: [(name: String, description: String)] = [
        ("Box", "Equal 4-second intervals for focus and calm. Great for stress relief."),
        ("4-7-8", "Inhale 4s, hold 7s, exhale 8s. Promotes deep relaxation and sleep."),
        ("Equal Breath", "Simple equal inhale/exhale rhythm for balance and presence."),
        ("Resonant 5.5", "5.5-second breaths for optimal heart rate variability.")
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(patterns, id: \.name) { pattern in
                Button(action: {
                    selectedPattern = pattern.name
                    onPatternChanged?()
                }) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(pattern.name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(selectedPattern == pattern.name ? .white : Color.primary)
                            Spacer()
                            if selectedPattern == pattern.name {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(pattern.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(selectedPattern == pattern.name ? .white.opacity(0.9) : Color.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPattern == pattern.name ? accentColor : Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPattern == pattern.name ? accentColor : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Walk Map View
private struct WalkMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: [CLLocationCoordinate2D]
    let userLocation: CLLocationCoordinate2D?
    let accentColor: Color
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add route polyline if we have points
        if route.count > 1 {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            mapView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(accentColor: accentColor)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let accentColor: Color
        
        init(accentColor: Color) {
            self.accentColor = accentColor
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(accentColor)
                renderer.lineWidth = 4
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
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
