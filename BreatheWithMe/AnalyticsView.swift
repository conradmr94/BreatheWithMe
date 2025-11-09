//
//  AnalyticsView.swift
//  BreatheWithMe
//
//  Unified analytics view combining stats and analytics for all three features: Sleep, Focus, Breathing, plus Insights

import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    
    @State private var selectedTab: AnalyticsTab = .breathing
    
    private var profileTheme: ProfileTheme {
        themeManager.currentTheme
    }
    
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }
    
    private var resolvedColorScheme: ColorScheme {
        themeManager.colorScheme(for: systemColorScheme)
    }
    
    private var usesDarkAppearance: Bool {
        resolvedColorScheme == .dark
    }
    
    enum AnalyticsTab: String, CaseIterable {
        case breathing = "Breathe"
        case focus = "Focus"
        case sleep = "Sleep"
        case walk = "Walk"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .breathing: return "wind"
            case .focus: return "brain.head.profile"
            case .sleep: return "moon.stars.fill"
            case .walk: return "figure.walk"
            case .insights: return "sparkles"
            }
        }
    }
    
    var body: some View {
        let colors = themeColors
        let palette = AnalyticsPalette(colors: colors, usesDarkAppearance: usesDarkAppearance)
        return VStack(spacing: 0) {
            // Tab selector - using a horizontal scrollable picker for better layout
            HStack(spacing: 12) {
                Spacer()
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = tab
                        }
                    }) {
                        let isSelected = selectedTab == tab
                        VStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18, weight: .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundColor(isSelected ? colors.primaryText : colors.secondaryText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? colors.accent.opacity(usesDarkAppearance ? 0.7 : 1.0) : colors.cardBackground.opacity(usesDarkAppearance ? 0.45 : 0.85))
                                .shadow(color: isSelected ? colors.accent.opacity(0.35) : colors.cardShadow, radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding(.vertical, 12)
            
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .sleep:
                    SleepAnalyticsContent()
                case .focus:
                    FocusAnalyticsContent()
                case .breathing:
                    BreathingAnalyticsContent()
                case .walk:
                    WalkAnalyticsContent()
                case .insights:
                    CrossFeatureAnalyticsView()
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colors.backgroundTop,
                    colors.backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(resolvedColorScheme)
        .environment(\.analyticsPalette, palette)
    }
}

struct WalkAnalyticsContent: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    
    var body: some View {
        WalkStatsView()
            .environmentObject(themeManager)
    }
}

// MARK: - Breathing Analytics Content (Stats + Analytics)
struct BreathingAnalyticsContent: View {
    @Environment(\.analyticsPalette) private var palette
    
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTimeframe: Timeframe = .week
    @AppStorage("breatheStats") private var breatheStatsData: Data = Data()
    @StateObject private var userStatsManager = UserStatsManager()
    
    enum Timeframe: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    private var breatheStats: BreatheStats {
        get {
            if let decoded = try? JSONDecoder().decode(BreatheStats.self, from: breatheStatsData) {
                return decoded
            }
            return BreatheStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                breatheStatsData = encoded
            }
        }
    }
    
    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        
        return userStatsManager.sessionHistory.filter { session in
            session.activityType == .breathe && session.date >= weekStart
        }.count
    }
    
    private var breathingSessions: [EnhancedSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days, to: Date()) ?? Date()
        return sessionManager.breathingSessions(from: cutoff, to: Date())
    }
    
    private var averageStressReduction: Double? {
        sessionManager.averageStressReduction(days: selectedTimeframe.days)
    }
    
    private var currentStreak: Int {
        sessionManager.breathingStreak()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Breathing Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(palette.primaryText)
                    
                    // Timeframe selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // MARK: - Stats Section
                if breatheStats.sessionsCompleted > 0 {
                    // Overview Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Sessions")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(palette.secondaryText)
                                Text("\(breatheStats.sessionsCompleted)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(palette.primaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total Time")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(palette.secondaryText)
                                Text(breatheStats.totalTimeFormatted)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(palette.primaryText)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    // Average Duration
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(palette.accent)
                            
                            Text("Average Duration")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(palette.primaryText)
                        }
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text(breatheStats.averageDurationFormatted)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(palette.primaryText)
                            
                            Text("per session")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(palette.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    // Session Type Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 20))
                                .foregroundColor(palette.accent)
                            
                            Text("Session Types")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(palette.primaryText)
                        }
                        
                        // 4-7-8 Sessions
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4-7-8 Technique")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(palette.primaryText)
                                
                                Text("Inhale 4s • Hold 7s • Exhale 8s")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(palette.secondaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(breatheStats.sessions478)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(palette.accent)
                                
                                if breatheStats.sessionsCompleted > 0 {
                                    Text("\(Int(Double(breatheStats.sessions478) / Double(breatheStats.sessionsCompleted) * 100))%")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(palette.secondaryText)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(palette.elevatedAccent())
                        )
                        
                        // Standard Sessions
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Standard Breathing")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(palette.primaryText)
                                
                                Text("Custom interval breathing")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(palette.secondaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(breatheStats.standardSessions)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(palette.accent)
                                
                                if breatheStats.sessionsCompleted > 0 {
                                    Text("\(Int(Double(breatheStats.standardSessions) / Double(breatheStats.sessionsCompleted) * 100))%")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(palette.secondaryText)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(palette.elevatedAccent())
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(palette.highlight)
                                .frame(width: 24)
                            
                            Text("Longest Session")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(palette.secondaryText)
                            
                            Spacer()
                            
                            Text(breatheStats.longestSessionSeconds > 0 ? breatheStats.longestSessionFormatted : "—")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.primaryText)
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(palette.accent)
                                .frame(width: 24)
                            
                            Text("This Week")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(palette.secondaryText)
                            
                            Spacer()
                            
                            Text("\(sessionsThisWeek)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.primaryText)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "wind")
                            .font(.system(size: 48))
                            .foregroundColor(palette.secondaryText)
                        
                        Text("No Sessions Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                        
                        Text("Complete your first breathing session\nto see your statistics here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(palette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Analytics Section
                if !breathingSessions.isEmpty {
                    Divider()
                        .background(palette.separator)
                        .padding(.vertical, 8)
                    
                    Text("Analytics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(palette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    StreakCard(streak: currentStreak)
                    
                    if let reduction = averageStressReduction {
                        StressReductionCard(reduction: reduction, sessions: breathingSessions)
                    }
                    
                    ProtocolUsageChart(sessions: breathingSessions)
                    
                    BreathingFrequencyChart(sessions: breathingSessions)
                    
                    BreathingSummaryStats(sessions: breathingSessions)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Focus Analytics Content (Stats + Analytics)
struct FocusAnalyticsContent: View {
    @Environment(\.analyticsPalette) private var palette
    
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTimeframe: Timeframe = .week
    @AppStorage("focusStats") private var focusStatsData: Data = Data()
    @StateObject private var userStatsManager = UserStatsManager()
    
    enum Timeframe: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    private var focusStats: FocusStats {
        get {
            if let decoded = try? JSONDecoder().decode(FocusStats.self, from: focusStatsData) {
                return decoded
            }
            return FocusStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                focusStatsData = encoded
            }
        }
    }
    
    private var focusSessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        
        return userStatsManager.sessionHistory.filter { session in
            session.activityType == .focus && session.date >= weekStart
        }.count
    }
    
    private var focusSessions: [EnhancedSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days, to: Date()) ?? Date()
        return sessionManager.focusSessions(from: cutoff, to: Date())
    }
    
    private var completionRate: Double? {
        sessionManager.focusCompletionRate(days: selectedTimeframe.days)
    }
    
    private var bestHours: [Int] {
        sessionManager.bestFocusHours()
    }
    
    private var recommendedDuration: Int? {
        sessionManager.recommendedFocusDuration()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Focus Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(palette.primaryText)
                    
                    // Timeframe selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // MARK: - Stats Section
                if focusStats.focusSessionsCompleted > 0 {
                    // Overview Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Focus Sessions")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(palette.secondaryText)
                                Text("\(focusStats.focusSessionsCompleted)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(palette.highlight)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Focus Time")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(palette.secondaryText)
                                Text(focusStats.totalFocusTimeFormatted)
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(palette.highlight)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    // Average Durations
                    VStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 18))
                                    .foregroundColor(palette.highlight)
                                
                                Text("Avg Focus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(palette.secondaryText)
                            }
                            
                            Text(focusStats.averageFocusDurationFormatted)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(palette.primaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(palette.highlight.opacity(palette.usesDarkAppearance ? 0.25 : 0.12))
                        )
                        
                        HStack(spacing: 12) {
                            if focusStats.shortBreaksCompleted > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "cup.and.saucer.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(palette.accent)
                                        
                                        Text("Avg Short")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(palette.secondaryText)
                                    }
                                    
                                    Text(focusStats.averageShortBreakDurationFormatted)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(palette.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(palette.elevatedAccent())
                                )
                            }
                            
                            if focusStats.longBreaksCompleted > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "pause.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(palette.accent)
                                        
                                        Text("Avg Long")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(palette.secondaryText)
                                    }
                                    
                                    Text(focusStats.averageLongBreakDurationFormatted)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(palette.primaryText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(palette.elevatedAccent())
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Break Types
                    if focusStats.restSessionsCompleted > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(palette.accent)
                                
                                Text("Break Types")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(palette.primaryText)
                            }
                            
                            HStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("\(focusStats.shortBreaksCompleted)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(palette.accent)
                                    
                                    Text("Short Breaks")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(palette.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(palette.elevatedAccent())
                                )
                                
                                VStack(spacing: 8) {
                                    Text("\(focusStats.longBreaksCompleted)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(palette.accent)
                                    
                                    Text("Long Breaks")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(palette.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(palette.elevatedAccent())
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(palette.cardBackground)
                                .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                        
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(palette.highlight)
                                .frame(width: 24)
                            
                            Text("Longest Focus Session")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(palette.secondaryText)
                            
                            Spacer()
                            
                            Text(focusStats.longestFocusSessionSeconds > 0 ? focusStats.longestFocusSessionFormatted : "—")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.primaryText)
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(palette.accent)
                                .frame(width: 24)
                            
                            Text("This Week")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(palette.secondaryText)
                            
                            Spacer()
                            
                            Text("\(focusSessionsThisWeek)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.primaryText)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "timer")
                            .font(.system(size: 48))
                            .foregroundColor(palette.secondaryText)
                        
                        Text("No Sessions Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                        
                        Text("Complete your first focus session\nto see your statistics here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(palette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Analytics Section
                if !focusSessions.isEmpty {
                    Divider()
                        .background(palette.separator)
                        .padding(.vertical, 8)
                    
                    Text("Analytics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(palette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    if let rate = completionRate {
                        CompletionRateCard(rate: rate, sessions: focusSessions)
                    }
                    
                    TimeOfDayPerformanceChart(sessions: focusSessions)
                    
                    if let recommendation = recommendedDuration {
                        AdaptiveRecommendationCard(recommendedDuration: recommendation)
                    }
                    
                    DistractionCard(sessions: focusSessions)
                    
                    FocusDurationChart(sessions: focusSessions)
                    
                    FocusSummaryStats(sessions: focusSessions)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Sleep Analytics Content (Stats + Analytics)
struct SleepAnalyticsContent: View {
    @Environment(\.analyticsPalette) private var palette
    
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTimeframe: Timeframe = .week
    @StateObject private var vm = SleepViewModel()
    @AppStorage("sleepStats") private var sleepStatsData: Data = Data()
    
    enum Timeframe: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case threeMonths = "90 Days"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    private var sleepStats: SleepStats {
        if let decoded = try? JSONDecoder().decode(SleepStats.self, from: sleepStatsData) {
            return decoded
        }
        return SleepStats()
    }
    
    private var sleepSessions: [EnhancedSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days, to: Date()) ?? Date()
        return sessionManager.sleepSessions(from: cutoff, to: Date())
    }
    
    private var averageScore: Double? {
        sessionManager.averageSleepScore(days: selectedTimeframe.days)
    }
    
    private var bedtimeRegularity: (mean: Date, stdDev: TimeInterval)? {
        sessionManager.bedtimeRegularity(days: selectedTimeframe.days)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Sleep Analytics")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(palette.primaryText)
                    
                    // Timeframe selector
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.top)
                
                // MARK: - Stats Section
                // Local Sleep Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("In-App Sleep Sessions")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(palette.secondaryText)
                    
                    HStack {
                        Text("Completed Sessions")
                        Spacer()
                        Text("\(sleepStats.sleepSessionsCompleted)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                    }
                    
                    HStack {
                        Text("Total Sleep Time")
                        Spacer()
                        Text(sleepStats.sleepSessionsCompleted > 0 ? sleepStats.totalSleepTimeFormatted : "—")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                    }
                    
                    HStack {
                        Text("Average Session")
                        Spacer()
                        Text(sleepStats.averageSleepTimeFormatted)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                    }
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(palette.secondaryText)
                .frame(maxWidth: 360)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(palette.cardBackground)
                        .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
                
                // HealthKit Sleep Data
                if vm.isAuthorized {
                    if let lastNight = vm.lastNight {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HealthKit Sleep Data")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.secondaryText)
                            
                            HStack {
                                Text("Last Night Sleep")
                                Spacer()
                                Text(vm.formatHours(lastNight.totalHours))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(palette.primaryText)
                            }
                            HStack {
                                Text("14-Day Average")
                                Spacer()
                                Text(vm.formatHours(vm.rollingAvgHours14))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(palette.primaryText)
                            }
                            
                            Divider().padding(.vertical, 4)
                            
                            HStack {
                                Text("REM Sleep")
                                Spacer()
                                Text(String(format: "%.1fh", lastNight.stageHours(.rem)))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(palette.primaryText)
                            }
                            HStack {
                                Text("Deep Sleep")
                                Spacer()
                                Text(String(format: "%.1fh", lastNight.stageHours(.deep)))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(palette.primaryText)
                            }
                            HStack {
                                Text("Core Sleep")
                                Spacer()
                                Text(String(format: "%.1fh", lastNight.stageHours(.core)))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(palette.primaryText)
                            }
                        }
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                        .frame(maxWidth: 360)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(palette.cardBackground)
                                .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HealthKit Sleep Data")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(palette.secondaryText)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(palette.secondaryText.opacity(0.5))
                                
                                Text("No Sleep Data Available")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(palette.primaryText)
                                
                                Text("Track your sleep with Apple Watch or iPhone to see detailed sleep analysis here.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(palette.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                        .frame(maxWidth: 360)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(palette.cardBackground)
                                .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HealthKit Sleep Data")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.secondaryText)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 36))
                                .foregroundColor(palette.highlight.opacity(0.7))
                            
                            Text("HealthKit Not Authorized")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(palette.primaryText)
                            
                            Text("Enable HealthKit to see detailed sleep analysis from your Apple Watch or iPhone.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(palette.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 14))
                                    Text("Open Settings")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundColor(palette.cardBackground)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(palette.accent)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(palette.secondaryText)
                    .frame(maxWidth: 360)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(palette.cardBackground)
                            .shadow(color: palette.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                }
                
                // MARK: - Analytics Section
                if !sleepSessions.isEmpty {
                    Divider()
                        .background(palette.separator)
                        .padding(.vertical, 8)
                    
                    Text("Analytics")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(palette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    if let avgScore = averageScore {
                        SleepScoreCard(score: avgScore, sessions: sleepSessions)
                    }
                    
                    SleepDurationChart(sessions: sleepSessions)
                    
                    if let regularity = bedtimeRegularity {
                        BedtimeRegularityCard(regularity: regularity)
                    }
                    
                    SleepEventsCard(sessions: sleepSessions)
                    
                    SleepSummaryStats(sessions: sleepSessions)
                }
            }
            .padding()
            .padding(.bottom, 8)
        }
        .onAppear {
            vm.onAppear()
        }
    }
}

#Preview {
    NavigationView { AnalyticsView() }
}
