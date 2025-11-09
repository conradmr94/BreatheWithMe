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
    
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3347, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var showStats = false
    @State private var showPermissionsAlert = false
    @State private var hasRequestedHealthKit = false
    @State private var showDetails = false
    
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }
    
    private var palette: AnalyticsPalette {
        AnalyticsPalette(
            colors: themeColors,
            usesDarkAppearance: themeManager.colorScheme(for: systemColorScheme) == .dark
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
            walkContent
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
        }
        .onChange(of: walkManager.currentLocation) { _ in
            updateRegionIfNeeded()
        }
        .onChange(of: walkManager.authorizationDenied) { denied in
            if denied {
                showPermissionsAlert = true
            }
        }
    }
    
    @ViewBuilder
    private var navigationViewBody: some View {
        NavigationView {
            walkContent
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
        }
        .onChange(of: walkManager.currentLocation) { _ in
            updateRegionIfNeeded()
        }
        .onChange(of: walkManager.authorizationDenied) { denied in
            if denied {
                showPermissionsAlert = true
            }
        }
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
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    breathingPatternPicker
                    if walkManager.motionUnavailable {
                        motionAvailabilityNotice
                    }
                    breathingCircle
                    controlButtons
                    detailToggleButton
                    if showDetails {
                        detailMetricsStack
                    }
                    quickTips
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
    }
    
    // MARK: Sections
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Ground your mind with a gentle walk.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var breathingPatternPicker: some View {
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
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let scale = walkManager.currentPattern.normalizedScale(at: elapsed)
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                themeColors.accent.opacity(0.6),
                                themeColors.accent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 0.6), value: scale)
                
                VStack(spacing: 6) {
                    Image(systemName: "figure.walk.circle")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(themeColors.primaryText)
                    Text(walkManager.isWalking ? "Keep your pace steady" : "Tap start when ready")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
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
    
    private var controlButtons: some View {
        VStack(spacing: 12) {
            Button {
                walkManager.isWalking ? walkManager.stopSession() : walkManager.startSession()
            } label: {
                Text(walkManager.isWalking ? "Finish Walk" : "Start Walk")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                themeColors.accent,
                                themeColors.accent.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: themeColors.accent.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            
            if walkManager.isMetricsAvailable {
                Button(role: .destructive) {
                    walkManager.resetSession()
                } label: {
                    Text("Reset")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(themeColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeColors.cardBackground)
                        )
                }
            }
        }
    }
    
    private var detailToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                showDetails.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(showDetails ? "Hide walk metrics" : "Show walk metrics")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeColors.primaryText)
                    Text("Steps, distance, pace, calories, and route")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(themeColors.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeColors.secondaryText)
                    .rotationEffect(.degrees(showDetails ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: showDetails)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeColors.cardBackground)
                    .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var detailMetricsStack: some View {
        VStack(spacing: 24) {
            metricsCards
            mapSection
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
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
        .padding(.bottom, 12)
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
