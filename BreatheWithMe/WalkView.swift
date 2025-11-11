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
    @State private var activeInfoSheet: WalkSheet?
    @State private var showNoiseSettings = false
    
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
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

    private enum WalkSheet: Identifiable {
        case breathing, metrics, route, tips
        var id: String {
            switch self {
            case .breathing: return "breathing"
            case .metrics: return "metrics"
            case .route: return "route"
            case .tips: return "tips"
            }
        }

        var title: String {
            switch self {
            case .breathing: return "Breathing Pattern"
            case .metrics: return "Walk Metrics"
            case .route: return "Route"
            case .tips: return "Mindful Tips"
            }
        }
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
        .sheet(item: $activeInfoSheet) { sheet in
            infoSheetView(for: sheet)
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
        .sheet(item: $activeInfoSheet) { sheet in
            infoSheetView(for: sheet)
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
    }
    
    private var walkExperienceView: some View {
        walkContent
            .overlay(noiseInfoOverlay)
            .overlay(noiseSettingsOverlay)
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
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
                    accentColor: themeColors.accent,
                    isRunning: walkManager.isWalking,
                    title: "Walk Sounds"
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(2)
        }
    }
    
    private var bottomControlsSection: some View {
        VStack(spacing: 16) {
            infoButtonGrid
            soundButton
            if walkManager.isMetricsAvailable {
                resetButton
            }
            if walkManager.motionUnavailable {
                motionAvailabilityNotice
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var infoButtonGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                infoPill(icon: "wind", title: "Breathing") {
                    activeInfoSheet = .breathing
                }
                infoPill(icon: "chart.bar", title: "Metrics") {
                    activeInfoSheet = .metrics
                }
            }
            HStack(spacing: 12) {
                infoPill(icon: "map", title: "Route") {
                    activeInfoSheet = .route
                }
                infoPill(icon: "lightbulb", title: "Tips") {
                    activeInfoSheet = .tips
                }
            }
        }
    }
    
    private func infoPill(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                functionalButtonBackground(
                    isActive: false,
                    accentColor: themeColors.accent,
                    usesAccentFillWhenInactive: true,
                    cornerRadius: 18
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var soundButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showNoiseSettings = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: noiseGenerator.isEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                    .font(.system(size: 16, weight: .medium))
                Text("Walk Sounds")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(noiseGenerator.isEnabled ? .white : themeColors.primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                functionalButtonBackground(
                    isActive: noiseGenerator.isEnabled,
                    accentColor: themeColors.accent,
                    usesAccentFillWhenInactive: false,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var resetButton: some View {
        Button {
            walkManager.resetSession()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14, weight: .semibold))
                Text("Reset Session")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                functionalButtonBackground(
                    isActive: false,
                    accentColor: themeColors.accent,
                    usesAccentFillWhenInactive: false,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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
        Button(action: toggleWalkSession) {
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let scale = walkManager.currentPattern.normalizedScale(at: elapsed)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeColors.accent.opacity(0.65),
                                    themeColors.accent.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 240, height: 240)
                        .shadow(color: themeColors.accent.opacity(0.35), radius: 25, x: 0, y: 12)
                        .scaleEffect(scale)
                        .animation(.easeInOut(duration: 0.6), value: scale)
                    
                    VStack(spacing: 10) {
                        Image(systemName: walkManager.isWalking ? "figure.walk.circle.fill" : "figure.walk.circle")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(themeColors.primaryText)
                        Text(walkManager.isWalking ? walkManager.durationFormatted : walkManager.currentPattern.displayName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeColors.primaryText)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 8)
    }
    
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            WalkRouteMap(
                region: $mapRegion,
                route: walkManager.route,
                accentColor: UIColor(themeColors.accent)
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
    
    @ViewBuilder
    private func infoSheetView(for sheet: WalkSheet) -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                infoSheetContent(for: sheet)
            }
            .presentationDetents([.fraction(0.45), .large])
            .presentationDragIndicator(.visible)
        } else {
            NavigationView {
                infoSheetContent(for: sheet)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
    private func infoSheetContent(for sheet: WalkSheet) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                switch sheet {
                case .breathing:
                    breathingPatternCard
                case .metrics:
                    metricsCards
                case .route:
                    mapSection
                case .tips:
                    quickTips
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColors.backgroundTop,
                    themeColors.backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(sheet.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    activeInfoSheet = nil
                }
            }
        }
    }

    // MARK: Helpers
    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeColors.accent)
                
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
                .foregroundColor(themeColors.accent)
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
