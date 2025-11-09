//
//  WalkStatsView.swift
//  BreatheWithMe
//
//

import SwiftUI

struct WalkStatsView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    
    @AppStorage("walkStats") private var walkStatsData: Data = Data()
    @State private var walkStats = WalkStats()
    @State private var todaySteps: Double?
    @State private var todayDistance: Double?
    @State private var todayEnergy: Double?
    @State private var todayHeartRate: Double?
    @State private var todayStressRelief: Double?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }
    
    private var palette: AnalyticsPalette {
        AnalyticsPalette(
            colors: themeColors,
            usesDarkAppearance: themeManager.colorScheme(for: systemColorScheme) == .dark
        )
    }
    
    private var hasHistory: Bool {
        walkStats.walkSessionsCompleted > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                if let errorMessage {
                    errorState(errorMessage)
                }
                
                if !hasHistory && !isLoading {
                    emptyState
                }
                
                if hasHistory {
                    overviewCards
                    totalsCard
                    averagesCard
                    stressSummary
                }
                
                todaySection
            }
            .padding(24)
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
        .navigationTitle("Walk Stats")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadStoredStats()
            await loadTodayMetrics()
        }
        .refreshable {
            await loadTodayMetrics()
        }
    }
    
    // MARK: Sections
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Mindful Walking Insights")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeColors.primaryText)
            
            Text("Gentle movement, grounded presence.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(themeColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
            statCard(
                title: "Total Walks",
                value: "\(walkStats.walkSessionsCompleted)",
                subtitle: walkStats.walkSessionsCompleted == 1 ? "session" : "sessions",
                icon: "figure.walk",
                tint: palette.accent
            )
            statCard(
                title: "Distance",
                value: String(format: "%.1f km", walkStats.totalDistanceKilometers),
                subtitle: "all time",
                icon: "map.fill",
                tint: palette.highlight
            )
            statCard(
                title: "Steps",
                value: formattedNumber(walkStats.totalSteps),
                subtitle: "tracked",
                icon: "shoeprints.fill",
                tint: Color(red: 0.32, green: 0.65, blue: 0.6)
            )
            statCard(
                title: "Calories",
                value: walkStats.totalCaloriesFormatted,
                subtitle: "estimated kcal",
                icon: "flame.fill",
                tint: Color(red: 1.0, green: 0.58, blue: 0.42)
            )
            statCard(
                title: "Stress Relief",
                value: walkStats.averageStressFormatted,
                subtitle: "avg score /100",
                icon: "heart.text.square.fill",
                tint: palette.highlight
            )
        }
    }
    
    private var totalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Totals")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            VStack(spacing: 14) {
                totalsRow(
                    icon: "shoeprints.fill",
                    title: "Steps Taken",
                    value: formattedNumber(walkStats.totalSteps),
                    tint: palette.accent
                )
                
                Divider().background(themeColors.separator.opacity(0.6))
                
                totalsRow(
                    icon: "location.fill",
                    title: "Distance Covered",
                    value: String(format: "%.1f km", walkStats.totalDistanceKilometers),
                    tint: Color(red: 0.32, green: 0.65, blue: 0.6)
                )
                
                Divider().background(themeColors.separator.opacity(0.6))
                
                totalsRow(
                    icon: "clock.fill",
                    title: "Time Walking",
                    value: walkStats.totalTimeFormatted,
                    tint: palette.highlight
                )
                
                Divider().background(themeColors.separator.opacity(0.6))
                
                totalsRow(
                    icon: "flame.fill",
                    title: "Calories Burned",
                    value: "\(walkStats.totalCaloriesFormatted) kcal",
                    tint: Color(red: 1.0, green: 0.58, blue: 0.42)
                )
                
                if walkStats.averageStressReliefScore > 0 {
                    Divider().background(themeColors.separator.opacity(0.6))
                    totalsRow(
                        icon: "heart.text.square.fill",
                        title: "Avg Stress Relief",
                        value: "\(walkStats.averageStressFormatted) /100",
                        tint: palette.highlight
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    private var averagesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Averages Per Walk")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            VStack(spacing: 12) {
                averagesRow(
                    label: "Steps",
                    value: formattedNumber(walkStats.averageStepsPerWalk)
                )
                averagesRow(
                    label: "Distance",
                    value: distanceText(total: walkStats.averageDistanceMeters)
                )
                averagesRow(
                    label: "Duration",
                    value: walkStats.averageWalkDurationFormatted
                )
                averagesRow(
                    label: "Calories",
                    value: walkStats.averageCaloriesFormatted
                )
                averagesRow(
                    label: "Stress Relief",
                    value: walkStats.averageStressReliefScore > 0 ? "\(walkStats.averageStressFormatted) /100" : "--"
                )
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeColors.cardBackground)
                    .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 5)
            )
        }
    }
    
    @ViewBuilder
    private var stressSummary: some View {
        if walkStats.averageStressReliefScore > 0 {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(palette.highlight)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(palette.highlight.opacity(0.15))
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mind-body gains")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeColors.primaryText)
                        Text("Your average stress relief score is \(walkStats.averageStressFormatted) out of 100 across recorded walks.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeColors.secondaryText)
                    }
                }
                Text("Keep logging mindful walks to strengthen this trend.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeColors.secondaryText)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(themeColors.cardBackground)
                    .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 5)
            )
        }
    }
    
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Updating Health data…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 14) {
                    todayRow(
                        icon: "shoeprints.fill",
                        label: "Steps",
                        value: todaySteps.map(formattedNumber) ?? "--",
                        tint: palette.accent
                    )
                    todayRow(
                        icon: "location.fill",
                        label: "Distance",
                        value: todayDistance.map { distanceText(total: $0) } ?? "--",
                        tint: palette.highlight
                    )
                    todayRow(
                        icon: "flame.fill",
                        label: "Active Energy",
                        value: todayEnergy.map { String(format: "%.0f kcal", $0) } ?? "--",
                        tint: Color(red: 1.0, green: 0.58, blue: 0.42)
                    )
                    todayRow(
                        icon: "waveform.path.ecg",
                        label: "Heart Rate",
                        value: todayHeartRate.map { String(format: "%.0f bpm", $0) } ?? "--",
                        tint: Color(red: 0.43, green: 0.6, blue: 0.92)
                    )
                    todayRow(
                        icon: "bolt.heart.fill",
                        label: "Stress Relief",
                        value: todayStressRelief.map { String(format: "%.0f /100", $0) } ?? "--",
                        tint: palette.highlight
                    )
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(themeColors.cardBackground)
                        .shadow(color: themeColors.cardShadow, radius: 10, x: 0, y: 5)
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(themeColors.accent)
            Text("Your mindful walking journey starts here.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
                .multilineTextAlignment(.center)
            Text("When you complete your first mindful walk, your progress will appear here.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    private func errorState(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 22, weight: .semibold))
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: Helpers
    private func statCard(title: String, value: String, subtitle: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tint)
                Spacer()
            }
            Text(value)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(themeColors.primaryText)
            Text(subtitle.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(themeColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
    
    private func totalsRow(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(themeColors.primaryText)
            }
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeColors.primaryText)
        }
    }
    
    private func averagesRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeColors.primaryText)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeColors.primaryText)
        }
    }
    
    private func todayRow(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(tint)
                .frame(width: 26)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeColors.primaryText)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeColors.primaryText)
        }
    }
    
    private func distanceText(total: Double) -> String {
        let usesMetric = Locale.current.usesMetricSystem
        if usesMetric {
            return String(format: "%.2f km", total / 1_000.0)
        } else {
            return String(format: "%.2f mi", total / 1_609.34)
        }
    }
    
    private func formattedNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
    
    private func loadStoredStats() {
        if let decoded = try? JSONDecoder().decode(WalkStats.self, from: walkStatsData) {
            walkStats = decoded
        } else {
            walkStats = WalkStats()
        }
    }
    
    private func loadTodayMetrics() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await HealthKitManager.shared.requestAuthorization()
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: Date())
            let interval = DateInterval(start: start, end: Date())
            
            async let steps = HealthKitManager.shared.stepCount(for: interval)
            async let distance = HealthKitManager.shared.walkingDistance(for: interval)
            async let energy = HealthKitManager.shared.activeEnergy(for: interval)
            async let heartRate = HealthKitManager.shared.averageHeartRate(for: interval)
            
            let (stepResult, distanceResult, energyResult, heartRateResult) = try await (steps, distance, energy, heartRate)
            let estimatedDuration = WalkSessionManager.estimatedDuration(fromSteps: Int(stepResult))
            let stressScore = WalkSessionManager.stressReliefScore(forSteps: Int(stepResult), durationSeconds: estimatedDuration)
            await MainActor.run {
                todaySteps = stepResult
                todayDistance = distanceResult
                todayEnergy = energyResult
                todayHeartRate = heartRateResult
                todayStressRelief = stressScore > 0 ? stressScore : nil
                errorMessage = nil
            }
        } catch let hkError as HealthKitAccessError {
            await MainActor.run {
                switch hkError {
                case .unavailable:
                    errorMessage = "Health data isn’t available in the simulator. Recorded walk sessions will still appear once you log them on a device."
                case .authorizationDenied:
                    errorMessage = "Health permissions were denied. Open Settings › Health › Data Access and allow BreatheWithMe to read steps, distance, and energy."
                case .authorizationRestricted:
                    errorMessage = "Health permissions are restricted on this device."
                case .authorizationNotDetermined:
                    errorMessage = "Health permissions haven’t been granted yet."
                case .underlying(let error):
                    errorMessage = "Unable to read Health data: \(error.localizedDescription)"
                }
                todayStressRelief = nil
            }
        } catch {
            await MainActor.run {
                errorMessage = "Unable to read Health data: \(error.localizedDescription)"
                todayStressRelief = nil
            }
        }
    }

    private var stressReliefCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Relief Trend")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(themeColors.primaryText)
            
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundColor(palette.highlight)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.0f", walkStats.averageStressReliefScore))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeColors.primaryText)
                    Text("Average stress relief score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColors.secondaryText)
                }
                Spacer()
            }
            
            Text("The score blends steps and active time from each walk (0-100). Higher scores mean stronger stress relief impact.")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(themeColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeColors.cardBackground)
                .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
        )
    }
}

#Preview {
    WalkStatsView()
        .environmentObject(AppThemeManager())
}

