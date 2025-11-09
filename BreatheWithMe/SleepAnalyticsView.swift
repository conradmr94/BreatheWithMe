//
//  SleepAnalyticsView.swift
//  BreatheWithMe
//
//  Comprehensive sleep analytics and trends
//

import SwiftUI
import Charts

struct SleepAnalyticsView: View {
    @EnvironmentObject private var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    
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
    
    private var resolvedColorScheme: ColorScheme {
        themeManager.colorScheme(for: systemColorScheme)
    }
    
    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }
    
    private var palette: AnalyticsPalette {
        AnalyticsPalette(colors: themeColors, usesDarkAppearance: resolvedColorScheme == .dark)
    }
    
    var body: some View {
        let colors = themeColors
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
                
                // Sleep Score Card
                if let avgScore = averageScore {
                    SleepScoreCard(score: avgScore, sessions: sleepSessions)
                }
                
                // Duration Trend Chart
                if !sleepSessions.isEmpty {
                    SleepDurationChart(sessions: sleepSessions)
                }
                
                // Bedtime Regularity
                if let regularity = bedtimeRegularity {
                    BedtimeRegularityCard(regularity: regularity)
                }
                
                // Sleep Events Timeline
                if !sleepSessions.isEmpty {
                    SleepEventsCard(sessions: sleepSessions)
                }
                
                // Summary Stats
                SleepSummaryStats(sessions: sleepSessions)
            }
            .padding()
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
        )
        .preferredColorScheme(resolvedColorScheme)
        .environment(\.analyticsPalette, palette)
    }
}

// MARK: - Sleep Score Card
struct SleepScoreCard: View {
    let score: Double
    let sessions: [EnhancedSession]
    @Environment(\.analyticsPalette) private var palette
    
    private var scoreColor: Color {
        if score >= 80 {
            return palette.highlight
        } else if score >= 60 {
            return palette.accent
        } else {
            return palette.accent.opacity(0.7)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Sleep Score")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(palette.primaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(Int(score))")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(scoreColor)
                
                Text("/ 100")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(palette.secondaryText)
            }
            
            // Score breakdown
            if !sessions.isEmpty {
                let scores = sessions.compactMap { $0.meta.sleepScore }
                if !scores.isEmpty {
                    let excellent = scores.filter { $0 >= 80 }.count
                    let good = scores.filter { $0 >= 60 && $0 < 80 }.count
                    let poor = scores.filter { $0 < 60 }.count
                    
                    HStack(spacing: 16) {
                        StatBadge(label: "Excellent", count: excellent, color: palette.highlight)
                        StatBadge(label: "Good", count: good, color: palette.accent)
                        StatBadge(label: "Poor", count: poor, color: palette.accent.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .analyticsCardStyle(palette, shadowRadius: 20, shadowYOffset: 10)
    }
}

// MARK: - Sleep Duration Chart
struct SleepDurationChart: View {
    let sessions: [EnhancedSession]
    @Environment(\.analyticsPalette) private var palette
    
    private var chartData: [(date: Date, hours: Double)] {
        let calendar = Calendar.current
        var dayTotals: [Date: Int] = [:]
        
        for session in sessions {
            let day = calendar.startOfDay(for: session.start)
            dayTotals[day, default: 0] += session.durationSeconds
        }
        
        return dayTotals.map { (date: $0.key, hours: Double($0.value) / 3600.0) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Duration Trend")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            if #available(iOS 16.0, *) {
                Chart(chartData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Hours", dataPoint.hours)
                    )
                    .foregroundStyle(palette.accent)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartData.count > 14 ? 2 : 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback for iOS 15
                SimpleBarChart(data: chartData.map { $0.hours })
                    .frame(height: 200)
            }
        }
        .padding()
        .analyticsCardStyle(palette, shadowRadius: 20, shadowYOffset: 10)
    }
}

// MARK: - Bedtime Regularity Card
struct BedtimeRegularityCard: View {
    let regularity: (mean: Date, stdDev: TimeInterval)
    @Environment(\.analyticsPalette) private var palette
    
    private var meanTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: regularity.mean)
    }
    
    private var regularityStatus: (text: String, color: Color) {
        let stdDevMinutes = regularity.stdDev / 60
        if stdDevMinutes < 15 {
            return ("Very Regular", palette.highlight)
        } else if stdDevMinutes < 30 {
            return ("Regular", palette.accent)
        } else {
            return ("Irregular", palette.accent.opacity(0.7))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bedtime Regularity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(meanTimeString)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(palette.primaryText)
                
                Text("avg bedtime")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(palette.secondaryText)
            }
            
            HStack {
                Text(regularityStatus.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(regularityStatus.color)
                
                Spacer()
                
                Text("±\(Int(regularity.stdDev / 60)) min")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(palette.secondaryText)
            }
        }
        .padding()
        .analyticsCardStyle(palette, shadowRadius: 20, shadowYOffset: 10)
    }
}

// MARK: - Sleep Events Card
struct SleepEventsCard: View {
    let sessions: [EnhancedSession]
    @Environment(\.analyticsPalette) private var palette
    
    private var totalSnoreMinutes: Int {
        sessions.compactMap { $0.meta.snoreMinutes }.reduce(0, +)
    }
    
    private var totalWakeups: Int {
        sessions.compactMap { $0.meta.wakeups }.reduce(0, +)
    }
    
    private var averageWakeups: Double {
        let wakeupCounts = sessions.compactMap { $0.meta.wakeups }
        guard !wakeupCounts.isEmpty else { return 0 }
        return Double(wakeupCounts.reduce(0, +)) / Double(wakeupCounts.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Events")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalSnoreMinutes)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(palette.highlight)
                    Text("min snoring")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(averageWakeups))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(palette.accent)
                    Text("avg wakeups")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding()
        .analyticsCardStyle(palette, shadowRadius: 20, shadowYOffset: 10)
    }
}

// MARK: - Sleep Summary Stats
struct SleepSummaryStats: View {
    let sessions: [EnhancedSession]
    @Environment(\.analyticsPalette) private var palette
    
    private var totalSleepHours: Double {
        Double(sessions.reduce(0) { $0 + $1.durationSeconds }) / 3600.0
    }
    
    private var averageSleepHours: Double {
        guard !sessions.isEmpty else { return 0 }
        return totalSleepHours / Double(sessions.count)
    }
    
    private var longestSession: EnhancedSession? {
        sessions.max(by: { $0.durationSeconds < $1.durationSeconds })
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Sleep",
                    value: String(format: "%.1fh", totalSleepHours),
                    icon: "moon.stars.fill"
                )
                
                StatCard(
                    title: "Avg Duration",
                    value: String(format: "%.1fh", averageSleepHours),
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Sessions",
                    value: "\(sessions.count)",
                    icon: "bed.double.fill"
                )
            }
        }
        .padding()
        .analyticsCardStyle(palette, shadowRadius: 20, shadowYOffset: 10)
    }
}

// MARK: - Helper Views
struct StatBadge: View {
    let label: String
    let count: Int
    let color: Color
    @Environment(\.analyticsPalette) private var palette
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(label): \(count)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.secondaryText)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.analyticsPalette) private var palette
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(palette.accent)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(palette.primaryText)
            
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(palette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(palette.accentSoft)
        )
    }
}

// MARK: - Simple Bar Chart for iOS 15
struct SimpleBarChart: View {
    let data: [Double]
    @Environment(\.analyticsPalette) private var palette
    
    private var maxValue: Double {
        data.max() ?? 1.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(palette.accent)
                        .frame(
                            width: (geometry.size.width - CGFloat(data.count - 1) * 4) / CGFloat(data.count),
                            height: geometry.size.height * CGFloat(value / maxValue)
                        )
                }
            }
        }
    }
}

#Preview {
    SleepAnalyticsView()
}
