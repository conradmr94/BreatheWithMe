//
//  AnalyticsView.swift
//  BreatheWithMe
//
//  Unified analytics view for all three features: Sleep, Focus, Breathing, plus Insights

import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var selectedTab: AnalyticsTab = .sleep
    
    enum AnalyticsTab: String, CaseIterable {
        case sleep = "Sleep"
        case focus = "Focus"
        case breathing = "Breathe"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .sleep: return "moon.stars.fill"
            case .focus: return "brain.head.profile"
            case .breathing: return "wind"
            case .insights: return "sparkles"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector - using a horizontal scrollable picker for better layout
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(selectedTab == tab ? .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedTab == tab ? Color(red: 0.4, green: 0.5, blue: 0.8) : Color.white.opacity(0.3))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
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
                case .insights:
                    CrossFeatureAnalyticsView()
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.93, blue: 0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Sleep Analytics Content
struct SleepAnalyticsContent: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTimeframe: Timeframe = .week
    
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
                        .foregroundColor(.white)
                    
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
                
                // Import existing sleep analytics components
                if let avgScore = averageScore {
                    SleepScoreCard(score: avgScore, sessions: sleepSessions)
                }
                
                if !sleepSessions.isEmpty {
                    SleepDurationChart(sessions: sleepSessions)
                }
                
                if let regularity = bedtimeRegularity {
                    BedtimeRegularityCard(regularity: regularity)
                }
                
                if !sleepSessions.isEmpty {
                    SleepEventsCard(sessions: sleepSessions)
                }
                
                SleepSummaryStats(sessions: sleepSessions)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - Focus Analytics Content
struct FocusAnalyticsContent: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTimeframe: Timeframe = .week
    
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
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
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
                
                // Import existing focus analytics components
                if let rate = completionRate {
                    CompletionRateCard(rate: rate, sessions: focusSessions)
                }
                
                if !focusSessions.isEmpty {
                    TimeOfDayPerformanceChart(sessions: focusSessions)
                }
                
                if let recommendation = recommendedDuration {
                    AdaptiveRecommendationCard(recommendedDuration: recommendation)
                }
                
                if !focusSessions.isEmpty {
                    DistractionCard(sessions: focusSessions)
                }
                
                if !focusSessions.isEmpty {
                    FocusDurationChart(sessions: focusSessions)
                }
                
                FocusSummaryStats(sessions: focusSessions)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.93, blue: 0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.light)
    }
}

// MARK: - Breathing Analytics Content
struct BreathingAnalyticsContent: View {
    @StateObject private var sessionManager = SessionManager.shared
    @State private var selectedTimeframe: Timeframe = .week
    
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
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
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
                
                // Import existing breathing analytics components
                StreakCard(streak: currentStreak)
                
                if let reduction = averageStressReduction {
                    StressReductionCard(reduction: reduction, sessions: breathingSessions)
                }
                
                if !breathingSessions.isEmpty {
                    ProtocolUsageChart(sessions: breathingSessions)
                }
                
                if !breathingSessions.isEmpty {
                    BreathingFrequencyChart(sessions: breathingSessions)
                }
                
                BreathingSummaryStats(sessions: breathingSessions)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.88, green: 0.93, blue: 0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .preferredColorScheme(.light)
    }
}

#Preview {
    NavigationView { AnalyticsView() }
}

