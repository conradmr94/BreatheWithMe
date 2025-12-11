//
//  CrossFeatureAnalyticsView.swift
//  BreatheWithMe
//
//  Cross-feature analytics: correlations, daily readiness, content suggestions
//

import SwiftUI
import Charts

struct CrossFeatureAnalyticsView: View {
    @Environment(\.analyticsPalette) private var palette
    @StateObject private var sessionManager = SessionManager.shared
    
    private var sleepFocusCorrelation: (lowSleep: Double, highSleep: Double)? {
        sessionManager.sleepFocusCorrelation(days: 30)
    }
    
    private var dailyReadiness: String {
        sessionManager.dailyReadiness()
    }
    
    private var contentSuggestions: [(contentId: String, count: Int, suggestion: String)] {
        sessionManager.contentSuggestions()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Insights")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(palette.primaryText)
                    .padding(.top)
                
                // Feature Summary Card - Overview of all three features
                FeatureSummaryCard()
                
                // Daily Readiness Card
                DailyReadinessCard(readiness: dailyReadiness)
                
                // Walk Impact Card
                WalkImpactCard()
                
                // Sleep-Focus Correlation
                if let correlation = sleepFocusCorrelation {
                    SleepFocusCorrelationCard(correlation: correlation)
                }
                
                // Content Suggestions
                if !contentSuggestions.isEmpty {
                    ContentSuggestionsCard(suggestions: contentSuggestions)
                }
                
                // Activity Balance
                ActivityBalanceCard()
            }
            .padding()
        }
    }
}

// MARK: - Feature Summary Card
struct FeatureSummaryCard: View {
    @Environment(\.analyticsPalette) private var palette
    @StateObject private var sessionManager = SessionManager.shared
    
    private var sleepStats: (avgDuration: String, totalTime: String, sessions: Int) {
        let sessions = sessionManager.sessions(ofType: .sleep, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        let totalSeconds = sessions.reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start)) }
        let avgSeconds = sessions.isEmpty ? 0 : totalSeconds / sessions.count
        let avgHours = avgSeconds / 3600
        let avgMinutes = (avgSeconds % 3600) / 60
        let avgDuration = avgHours > 0 ? "\(avgHours)h \(avgMinutes)m" : "\(avgMinutes)m"
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let totalTime = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return (avgDuration, totalTime, sessions.count)
    }
    
    private var focusStats: (completionRate: Int, totalTime: String, sessions: Int) {
        let sessions = sessionManager.sessions(ofType: .focus, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        let completed = sessions.filter { $0.meta.completed == true }.count
        let completionRate = sessions.isEmpty ? 0 : Int((Double(completed) / Double(sessions.count)) * 100)
        let totalSeconds = sessions.reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start)) }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let totalTime = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return (completionRate, totalTime, sessions.count)
    }
    
    private var breathingStats: (avgStressReduction: Double, totalTime: String, sessions: Int) {
        let sessions = sessionManager.sessions(ofType: .breathing, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        let stressReductions = sessions.compactMap { session -> Double? in
            guard let pre = session.meta.preStressLevel,
                  let post = session.meta.postStressLevel else { return nil }
            return Double(pre - post)
        }
        let avgReduction = stressReductions.isEmpty ? 0.0 : stressReductions.reduce(0.0, +) / Double(stressReductions.count)
        let totalSeconds = sessions.reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start)) }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let totalTime = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return (avgReduction, totalTime, sessions.count)
    }
    
    private var walkStats: (steps: Int, distanceKm: Double, calories: Double, stress: Double, sessions: Int) {
        let summary = sessionManager.walkSummary(days: 30)
        return (
            steps: summary.steps,
            distanceKm: summary.distanceMeters / 1_000.0,
            calories: summary.calories,
            stress: summary.stress,
            sessions: summary.sessions
        )
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("30-Day Summary")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(palette.primaryText)
            
            // Sleep Summary
            FeatureStatRow(
                icon: "moon.stars.fill",
                title: "Sleep",
                color: Color(red: 0.4, green: 0.5, blue: 0.8),
                primaryStat: sleepStats.avgDuration,
                primaryLabel: "Avg Duration",
                secondaryStat: sleepStats.totalTime,
                secondaryLabel: "Total Time",
                tertiaryStat: "\(sleepStats.sessions)",
                tertiaryLabel: "Sessions"
            )
            
            Divider()
                .background(palette.separator)
            
            // Focus Summary
            FeatureStatRow(
                icon: "brain.head.profile",
                title: "Focus",
                color: Color(red: 0.9, green: 0.6, blue: 0.5),
                primaryStat: "\(focusStats.completionRate)%",
                primaryLabel: "Completion",
                secondaryStat: focusStats.totalTime,
                secondaryLabel: "Total Time",
                tertiaryStat: "\(focusStats.sessions)",
                tertiaryLabel: "Sessions"
            )
            
            Divider()
                .background(palette.separator)
            
            // Breathing Summary
            FeatureStatRow(
                icon: "wind",
                title: "Breathe",
                color: Color(red: 0.65, green: 0.8, blue: 0.92),
                primaryStat: String(format: "%.1f", breathingStats.avgStressReduction),
                primaryLabel: "Avg Stress ↓",
                secondaryStat: breathingStats.totalTime,
                secondaryLabel: "Total Time",
                tertiaryStat: "\(breathingStats.sessions)",
                tertiaryLabel: "Sessions"
            )
            
            Divider()
                .background(palette.separator)
            
            // Walk Summary
            FeatureStatRow(
                icon: "figure.walk.circle.fill",
                title: "Walk",
                color: Color(red: 0.32, green: 0.65, blue: 0.6),
                primaryStat: numberFormatter.string(from: NSNumber(value: walkStats.steps)) ?? "0",
                primaryLabel: "Steps",
                secondaryStat: String(format: "%.1f km", walkStats.distanceKm),
                secondaryLabel: "Distance",
                tertiaryStat: walkStats.calories > 0 ? String(format: "%.0f kcal", walkStats.calories) : "--",
                tertiaryLabel: "Calories"
            )
            
            if walkStats.stress > 0 {
                Text("Average stress relief score: \(String(format: "%.0f /100", walkStats.stress))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.secondaryText)
            }
        }
        .padding()
        .analyticsCardStyle(palette)
    }
}

// MARK: - Feature Stat Row
struct FeatureStatRow: View {
    let icon: String
    let title: String
    let color: Color
    let primaryStat: String
    let primaryLabel: String
    let secondaryStat: String
    let secondaryLabel: String
    let tertiaryStat: String
    let tertiaryLabel: String
    @Environment(\.analyticsPalette) private var palette
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            // Title
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
                .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(primaryStat)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                    Text(primaryLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(secondaryStat)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.primaryText)
                    Text(secondaryLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(tertiaryStat)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(palette.primaryText)
                    Text(tertiaryLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                }
            }
        }
    }
}

// MARK: - Daily Readiness Card
struct DailyReadinessCard: View {
    let readiness: String
    @Environment(\.analyticsPalette) private var palette
    
    private var readinessColor: Color {
        switch readiness {
        case "Push":
            return palette.highlight
        case "Normal":
            return palette.accent
        case "Light":
            return palette.accent.opacity(0.8)
        default:
            return palette.secondaryText
        }
    }
    
    private var readinessMessage: String {
        switch readiness {
        case "Push":
            return "You're well-rested. Great day to tackle challenging tasks!"
        case "Normal":
            return "You're in good shape. Maintain your usual pace."
        case "Light":
            return "Take it easy today. Focus on lighter activities."
        default:
            return "Keep up your routine."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 32))
                    .foregroundColor(readinessColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.secondaryText)
                    
                    Text(readiness)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(readinessColor)
                }
                
                Spacer()
            }
            
            Text(readinessMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(palette.secondaryText)
        }
        .padding()
        .analyticsCardStyle(palette)
    }
}

// MARK: - Walk Impact Card
struct WalkImpactCard: View {
    @Environment(\.analyticsPalette) private var palette
    @StateObject private var sessionManager = SessionManager.shared
    
    private var summary: (distanceKm: Double, steps: Int, calories: Double, stress: Double, sessions: Int) {
        let data = sessionManager.walkSummary(days: 7)
        return (
            distanceKm: data.distanceMeters / 1_000.0,
            steps: data.steps,
            calories: data.calories,
            stress: data.stress,
            sessions: data.sessions
        )
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mindful Walk Highlights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            Text("Past 7 days")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(palette.secondaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                statBlock(
                    value: numberFormatter.string(from: NSNumber(value: summary.steps)) ?? "0",
                    label: "Steps"
                )
                statBlock(
                    value: String(format: "%.1f km", summary.distanceKm),
                    label: "Distance"
                )
                statBlock(
                    value: String(format: "%.0f kcal", summary.calories),
                    label: "Calories"
                )
                statBlock(
                    value: summary.stress > 0 ? String(format: "%.0f /100", summary.stress) : "--",
                    label: "Stress Relief"
                )
            }
            
            if summary.sessions > 0 {
                Text("Logged \(summary.sessions) mindful walks this week")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.secondaryText)
            }
        }
        .padding()
        .analyticsCardStyle(palette)
    }
    
    private func statBlock(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(palette.primaryText)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sleep-Focus Correlation Card
struct SleepFocusCorrelationCard: View {
    let correlation: (lowSleep: Double, highSleep: Double)
    @Environment(\.analyticsPalette) private var palette
    
    private var difference: Double {
        correlation.highSleep - correlation.lowSleep
    }
    
    private var differencePercent: Int {
        guard correlation.lowSleep > 0 else { return 0 }
        return Int((difference / correlation.lowSleep) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep → Focus Connection")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            if #available(iOS 16.0, *) {
                Chart {
                    BarMark(
                        x: .value("Completion Rate", correlation.lowSleep),
                        y: .value("Sleep", "Less than 6h")
                    )
                    .foregroundStyle(palette.accent.opacity(0.45))
                    
                    BarMark(
                        x: .value("Completion Rate", correlation.highSleep),
                        y: .value("Sleep", "6h or more")
                    )
                    .foregroundStyle(palette.highlight.opacity(0.7))
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(Int(doubleValue * 100))%")
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("< 6h sleep")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(palette.secondaryText)
                        
                        Text(String(format: "%.0f%%", correlation.lowSleep * 100))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(palette.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("≥ 6h sleep")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(palette.secondaryText)
                        
                        Text(String(format: "%.0f%%", correlation.highSleep * 100))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(palette.highlight)
                    }
                }
            }
            
            if difference > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(palette.highlight)
                    
                    Text("With 6+ hours of sleep, your focus completion rate is \(differencePercent)% higher")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(palette.secondaryText)
                }
            }
        }
        .padding()
        .analyticsCardStyle(palette)
    }
}

// MARK: - Content Suggestions Card
struct ContentSuggestionsCard: View {
    let suggestions: [(contentId: String, count: Int, suggestion: String)]
    @Environment(\.analyticsPalette) private var palette
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content Suggestions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(palette.accent)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.contentId.capitalized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(palette.primaryText)
                        
                        Text(suggestion.suggestion)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(palette.secondaryText)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(palette.accentSoft)
                )
            }
        }
        .padding()
        .analyticsCardStyle(palette)
    }
}

// MARK: - Activity Balance Card
struct ActivityBalanceCard: View {
    @Environment(\.analyticsPalette) private var palette
    @StateObject private var sessionManager = SessionManager.shared
    
    private var activityDistribution: [(type: String, count: Int, color: Color)] {
        let sleep = sessionManager.sessions(ofType: .sleep, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        let focus = sessionManager.sessions(ofType: .focus, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        let breathing = sessionManager.sessions(ofType: .breathing, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        let walk = sessionManager.sessions(ofType: .walk, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        
        return [
            (type: "Sleep", count: sleep, color: Color(red: 0.4, green: 0.5, blue: 0.8)),
            (type: "Focus", count: focus, color: Color(red: 0.9, green: 0.6, blue: 0.5)),
            (type: "Breathe", count: breathing, color: Color(red: 0.65, green: 0.8, blue: 0.92)),
            (type: "Walk", count: walk, color: Color(red: 0.32, green: 0.65, blue: 0.6))
        ].sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Balance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(palette.primaryText)
            
            Text("Last 30 days")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(palette.secondaryText)
            
            if #available(iOS 16.0, *) {
                Chart(activityDistribution, id: \.type) { data in
                    BarMark(
                        x: .value("Sessions", data.count),
                        y: .value("Activity", data.type)
                    )
                    .foregroundStyle(data.color)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(activityDistribution, id: \.type) { data in
                        HStack {
                            Circle()
                                .fill(data.color)
                                .frame(width: 12, height: 12)
                            
                            Text(data.type)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(palette.primaryText)
                            
                            Spacer()
                            
                            Text("\(data.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(data.color)
                        }
                    }
                }
            }
        }
        .padding()
        .analyticsCardStyle(palette)
    }
}

#Preview {
    CrossFeatureAnalyticsView()
}

