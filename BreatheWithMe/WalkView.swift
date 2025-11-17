//
//  WalkView.swift
//  BreatheWithMe
//
//

import SwiftUI
import MapKit
import CoreMotion

struct WalkView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @StateObject private var walkManager = WalkSessionManager.shared
    @StateObject private var noiseGenerator = NoiseGenerator()
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3347, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showStats = false
    @State private var showPermissionsAlert = false
    @State private var hasRequestedHealthKit = false
    @State private var showNoiseSettings = false
    @State private var showSessionPanel = false
    @State private var showInsightsPanel = false
    @State private var showProfile = false
    
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }
    
    // Soothing light green accent color for Walk view
    private var walkAccentColor: Color {
        Color(red: 0.5, green: 0.8, blue: 0.65)
    }
    
    private var usesDarkAppearance: Bool {
        themeManager.colorScheme(for: systemColorScheme) == .dark
    }
    
    private var controlSurfaceColor: Color {
        usesDarkAppearance ? themeColors.cardBackground.opacity(0.7) : themeColors.cardBackground.opacity(0.96)
    }
    
    private var controlBorderColor: Color {
        usesDarkAppearance ? Color.white.opacity(0.15) : themeColors.separator.opacity(0.85)
    }
    
    private func functionalButtonBackground(
        isActive: Bool,
        accentColor: Color,
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
    
    private var palette: AnalyticsPalette {
        AnalyticsPalette(
            colors: themeColors,
            usesDarkAppearance: usesDarkAppearance
        )
    }

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                navigationStackBody
            } else {
                navigationViewBody
            }
        }
    }
    
    @ViewBuilder
    @available(iOS 16.0, *)
    private var navigationStackBody: some View {
        NavigationStack {
            walkExperienceView
        }
        .navigationTitle("Mindful Walk")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showStats = true
                } label: {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
            }
        }
        .sheet(isPresented: $showStats) {
            WalkStatsView()
                .environmentObject(themeManager)
        }
        .alert("Permission Needed", isPresented: $showPermissionsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Walking sessions need access to Motion & Fitness and Location. Please enable them in Settings.")
        }
        .onAppear {
            updateRegionIfNeeded()
            requestAuthorizationsIfNeeded()
            updateNoiseState(isWalking: walkManager.isWalking)
        }
        .onChange(of: walkManager.currentLocation) { _ in
            updateRegionIfNeeded()
        }
        .onChange(of: walkManager.authorizationDenied) { denied in
            if denied {
                showPermissionsAlert = true
            }
        }
        .onChange(of: walkManager.isWalking) { isWalking in
            updateNoiseState(isWalking: isWalking)
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
            showNoiseSettings = false
        }
        .swipeDownToOpenProfile(isDisabled: showNoiseSettings || showSessionPanel || showInsightsPanel) {
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
        .toolbar(showProfile ? .hidden : .visible, for: .tabBar)
        .overlay(noiseInfoOverlay)
        .overlay(noiseSettingsOverlay)
        .overlay(sessionPanelOverlay)
        .overlay(insightsPanelOverlay)
    }
    
    @ViewBuilder
    private var navigationViewBody: some View {
        NavigationView {
            walkExperienceView
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .navigationTitle("Mindful Walk")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showStats = true
                } label: {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
            }
        }
        .sheet(isPresented: $showStats) {
            WalkStatsView()
                .environmentObject(themeManager)
        }
        .alert("Permission Needed", isPresented: $showPermissionsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Walking sessions need access to Motion & Fitness and Location. Please enable them in Settings.")
        }
        .onAppear {
            updateRegionIfNeeded()
            requestAuthorizationsIfNeeded()
            updateNoiseState(isWalking: walkManager.isWalking)
        }
        .onChange(of: walkManager.currentLocation) { _ in
            updateRegionIfNeeded()
        }
        .onChange(of: walkManager.authorizationDenied) { denied in
            if denied {
                showPermissionsAlert = true
            }
        }
        .onChange(of: walkManager.isWalking) { isWalking in
            updateNoiseState(isWalking: isWalking)
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
            showNoiseSettings = false
        }
        .swipeDownToOpenProfile(isDisabled: showNoiseSettings || showSessionPanel || showInsightsPanel) {
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
        .overlay(noiseInfoOverlay)
        .overlay(noiseSettingsOverlay)
        .overlay(sessionPanelOverlay)
        .overlay(insightsPanelOverlay)
    }
    
    private var walkExperienceView: some View {
        walkContent
            .ignoresSafeArea(.container, edges: .top)
    }
    
    private var walkContent: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColors.backgroundTop,
                    themeColors.backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 120)
                    .padding(.top, 50)
                
                Spacer()
                
                breathingCircle
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                bottomControlsSection
                    .frame(height: 170)
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 24)
        }
    }
    
    @ViewBuilder
    private var noiseInfoOverlay: some View {
        if noiseGenerator.showInfoMessage {
            VStack {
                Spacer()
                Text(noiseGenerator.infoMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(themeColors.cardBackground.opacity(0.9))
                            .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 6)
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
                Color.black.opacity(0.35)
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
                    accentColor: walkAccentColor,
                    isRunning: walkManager.isWalking,
                    title: "Walk Sounds"
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    private var sessionPanelOverlay: some View {
        walkPanelOverlay(title: "Session", isPresented: $showSessionPanel) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    breathingPatternCard
                    mapSection
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private var insightsPanelOverlay: some View {
        walkPanelOverlay(title: "Insights", isPresented: $showInsightsPanel) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    metricsCards
                    quickTips
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func walkPanelOverlay<Content: View>(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if isPresented.wrappedValue {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented.wrappedValue = false
                        }
                    }
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeColors.primaryText)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented.wrappedValue = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(themeColors.secondaryText.opacity(0.7))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    content()
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
                .frame(maxWidth: 360, maxHeight: 520)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(themeColors.cardBackground)
                        .shadow(color: themeColors.cardShadow, radius: 20, x: 0, y: 10)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var bottomControlsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                sessionButton
                walkSoundsButton
            }
            
            insightsButton
            
            if walkManager.motionUnavailable {
                motionAvailabilityNotice
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var walkSoundsButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showInsightsPanel = false
                showSessionPanel = false
                showNoiseSettings = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: noiseGenerator.isEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                    .font(.system(size: 16))
                Text("Sounds")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                functionalButtonBackground(
                    isActive: noiseGenerator.isEnabled,
                    accentColor: walkAccentColor,
                    usesAccentFillWhenInactive: false,
                    cornerRadius: 24
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var insightsButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showNoiseSettings = false
                showSessionPanel = false
                showInsightsPanel = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16))
                Text("Insights")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                functionalButtonBackground(
                    isActive: showInsightsPanel,
                    accentColor: walkAccentColor,
                    usesAccentFillWhenInactive: true,
                    cornerRadius: 20
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sessionButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showNoiseSettings = false
                showInsightsPanel = false
                showSessionPanel = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 16))
                Text("Session")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(1.5)
                if walkManager.isWalking {
                    Text("ACTIVE")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.white.opacity(0.15))
                        )
                }
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                functionalButtonBackground(
                    isActive: false,
                    accentColor: walkAccentColor,
                    usesAccentFillWhenInactive: true,
                    cornerRadius: 20
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: Sections
    private var headerSection: some View {
        VStack(spacing: 12) {
            if !walkManager.isWalking {
                Text("Walk")
                    .font(.system(size: 34, weight: .light, design: .default))
                    .foregroundColor(themeColors.primaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                Text("Ground your mind with a gentle walk.")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(themeColors.secondaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var breathingPatternCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breathing Pattern")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            Picker("Breathing Pattern", selection: $walkManager.currentPattern) {
                ForEach(WalkBreathingPattern.allCases) { pattern in
                    Text(pattern.displayName).tag(pattern)
                }
            }
            .pickerStyle(.segmented)
            
            Text(walkManager.currentPattern.guidance)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(themeColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 5)
        )
    }
    
    private var motionAvailabilityNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeColors.highlight)
            VStack(alignment: .leading, spacing: 4) {
                Text("Motion data unavailable")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeColors.primaryText)
                Text("Mindful Walk relies on Motion & Fitness access. This simulator can’t provide step counts, so live metrics stay at zero.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeColors.secondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    private var breathingCircle: some View {
        ZStack {
            // Ambient halo rings (mirrors BreatheView aesthetic) - outside button
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let breathingScale: CGFloat = walkManager.isWalking
                ? walkManager.currentPattern.normalizedScale(at: elapsed)
                : 1.0
                
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    walkAccentColor.opacity(0.2 - Double(index) * 0.05),
                                    walkAccentColor.opacity(0.08 - Double(index) * 0.025),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 150 + CGFloat(index) * 30
                            )
                        )
                        .frame(width: 300 + CGFloat(index) * 60, height: 300 + CGFloat(index) * 60)
                        .scaleEffect(walkManager.isWalking ? breathingScale * (1.0 + CGFloat(index) * 0.08) : 1.0)
                        .opacity(walkManager.isWalking ? (0.7 - Double(index) * 0.15) : 0.35)
                }
            }
            
            // Central breathing circle - only this is tappable
            Button(action: toggleWalkSession) {
                TimelineView(.animation) { timeline in
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let breathingScale: CGFloat = walkManager.isWalking
                    ? walkManager.currentPattern.normalizedScale(at: elapsed)
                    : 1.0
                    
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        walkAccentColor,
                                        walkAccentColor.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 220)
                            .scaleEffect(walkManager.isWalking ? breathingScale : 1.0)
                            .shadow(color: walkAccentColor.opacity(0.35), radius: 30, x: 0, y: 12)
                        
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 180, height: 180)
                            .scaleEffect(walkManager.isWalking ? breathingScale : 1.0)
                        
                        VStack(spacing: 10) {
                            if walkManager.isWalking {
                                Text("WALKING")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .tracking(2)
                                Text(walkManager.durationFormatted)
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.walk.circle")
                                        .font(.system(size: 42, weight: .thin))
                                        .foregroundColor(.white)
                                    Text("START")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .tracking(2)
                                    Text(walkManager.currentPattern.displayName.uppercased())
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                        .tracking(1.5)
                                }
                            }
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())
        }
        .frame(height: 450)
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            WalkRouteMap(
                region: $mapRegion,
                route: walkManager.route,
                accentColor: UIColor(walkAccentColor)
            )
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(themeColors.separator.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
        }
    }
    
    private var quickTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mindful Walking Tips")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            VStack(alignment: .leading, spacing: 10) {
                tipRow(icon: "waveform.path.ecg", title: "Sync Breath & Steps", message: "Match inhales and exhales with your footsteps to stay grounded.")
                tipRow(icon: "ear.fill", title: "Open Awareness", message: "Notice sounds, scents, and colors around you without judgement.")
                tipRow(icon: "heart.fill", title: "Celebrate Progress", message: "Each walk adds to your resilience. Keep your pace gentle and kind.")
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeColors.cardBackground)
                    .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
            )
        }
    }
    
    // MARK: Helpers
    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(walkAccentColor)
                
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(themeColors.secondaryText)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(themeColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 6)
        )
    }
    
    private func tipRow(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(walkAccentColor)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(themeColors.primaryText)
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeColors.secondaryText)
            }
        }
    }
    
    private var distanceText: String {
        if Locale.current.usesMetricSystem {
            return String(format: "%.2f km", walkManager.distanceKilometers)
        } else {
            return String(format: "%.2f mi", walkManager.distanceMiles)
        }
    }
    
    private func updateRegionIfNeeded() {
        guard let location = walkManager.currentLocation?.coordinate else { return }
        mapRegion = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        )
    }
    
    private func requestAuthorizationsIfNeeded() {
        if !hasRequestedHealthKit {
            hasRequestedHealthKit = true
            Task {
                try? await HealthKitManager.shared.requestAuthorization()
            }
        }
        
        walkManager.requestLocationAuthorization()
        walkManager.motionUnavailable = WalkSessionManager.motionUnavailableForUI
    }

    private func toggleWalkSession() {
        if walkManager.isWalking {
            walkManager.stopSession()
        } else {
            walkManager.startSession()
        }
    }

    private func updateNoiseState(isWalking: Bool) {
        if isWalking {
            if noiseGenerator.isEnabled {
                noiseGenerator.startNoise()
            }
        } else {
            noiseGenerator.stopNoise()
        }
    }

    private var metricsCards: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                metricCard(
                    title: "Steps",
                    value: "\(walkManager.steps)",
                    icon: "shoeprints.fill"
                )
                
                metricCard(
                    title: "Distance",
                    value: distanceText,
                    icon: "location.north.line.fill"
                )
            }
            
            HStack(spacing: 12) {
                metricCard(
                    title: "Time",
                    value: walkManager.durationFormatted,
                    icon: "clock.fill"
                )
                
                metricCard(
                    title: "Pace",
                    value: walkManager.paceText,
                    icon: "speedometer"
                )
            }
            
            HStack(spacing: 12) {
                metricCard(
                    title: "Calories",
                    value: String(format: "%.0f kcal", walkManager.caloriesBurned),
                    icon: "flame.fill"
                )
                
                metricCard(
                    title: "Stress Relief",
                    value: String(format: "%.0f /100", walkManager.stressReliefScore),
                    icon: "heart.text.square.fill"
                )
            }
        }
    }
    
    private struct WalkRouteMap: UIViewRepresentable {
        @Binding var region: MKCoordinateRegion
        var route: [CLLocationCoordinate2D]
        var accentColor: UIColor
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        func makeUIView(context: Context) -> MKMapView {
            let mapView = MKMapView()
            mapView.showsUserLocation = true
            mapView.delegate = context.coordinator
            mapView.isRotateEnabled = false
            mapView.pointOfInterestFilter = .excludingAll
            mapView.setRegion(region, animated: false)
            return mapView
        }
        
        func updateUIView(_ uiView: MKMapView, context: Context) {
            context.coordinator.parent = self
            let needsRegionUpdate = abs(uiView.region.center.latitude - region.center.latitude) > 0.0001 ||
            abs(uiView.region.center.longitude - region.center.longitude) > 0.0001
            if needsRegionUpdate {
                uiView.setRegion(region, animated: uiView.window != nil)
            }
            
            uiView.removeOverlays(uiView.overlays)
            if route.count > 1 {
                let polyline = MKPolyline(coordinates: route, count: route.count)
                uiView.addOverlay(polyline)
            }
            
            uiView.removeAnnotations(context.coordinator.annotations)
            context.coordinator.annotations.removeAll()
            if let start = route.first {
                let startAnnotation = MKPointAnnotation()
                startAnnotation.coordinate = start
                startAnnotation.title = "Start"
                uiView.addAnnotation(startAnnotation)
                context.coordinator.annotations.append(startAnnotation)
            }
        }
        
        final class Coordinator: NSObject, MKMapViewDelegate {
            var parent: WalkRouteMap
            var annotations: [MKAnnotation] = []
            
            init(parent: WalkRouteMap) {
                self.parent = parent
            }
            
            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                if let polyline = overlay as? MKPolyline {
                    let renderer = MKPolylineRenderer(polyline: polyline)
                    renderer.strokeColor = parent.accentColor.withAlphaComponent(0.85)
                    renderer.lineWidth = 5
                    renderer.lineCap = .round
                    return renderer
                }
                return MKOverlayRenderer(overlay: overlay)
            }
        }
    }
}
