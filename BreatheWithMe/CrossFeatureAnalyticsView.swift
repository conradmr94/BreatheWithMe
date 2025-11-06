//
//  CrossFeatureAnalyticsView.swift
//  BreatheWithMe
//
//  Cross-feature analytics: correlations, daily readiness, content suggestions
//

import SwiftUI
import Charts

struct CrossFeatureAnalyticsView: View {
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
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    .padding(.top)
                
                // Feature Summary Card - Overview of all three features
                FeatureSummaryCard()
                
                // Daily Readiness Card
                DailyReadinessCard(readiness: dailyReadiness)
                
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
    @StateObject private var sessionManager = SessionManager.shared
    
    private var sleepStats: (avgScore: Int, totalTime: String, sessions: Int) {
        let sessions = sessionManager.sessions(ofType: .sleep, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        let scores = sessions.compactMap { $0.meta.sleepScore }
        let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
        let totalSeconds = sessions.reduce(0) { $0 + Int($1.end.timeIntervalSince($1.start)) }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let totalTime = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return (avgScore, totalTime, sessions.count)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("30-Day Summary")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            // Sleep Summary
            FeatureStatRow(
                icon: "moon.stars.fill",
                title: "Sleep",
                color: Color(red: 0.4, green: 0.5, blue: 0.8),
                primaryStat: "\(sleepStats.avgScore)",
                primaryLabel: "Avg Score",
                secondaryStat: sleepStats.totalTime,
                secondaryLabel: "Total Time",
                tertiaryStat: "\(sleepStats.sessions)",
                tertiaryLabel: "Sessions"
            )
            
            Divider()
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
            
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
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
            
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
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
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
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
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(secondaryStat)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    Text(secondaryLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(tertiaryStat)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    Text(tertiaryLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
            }
        }
    }
}

// MARK: - Daily Readiness Card
struct DailyReadinessCard: View {
    let readiness: String
    
    private var readinessColor: Color {
        switch readiness {
        case "Push":
            return .green
        case "Normal":
            return Color(red: 0.65, green: 0.8, blue: 0.92)
        case "Light":
            return .orange
        default:
            return .gray
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
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    
                    Text(readiness)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(readinessColor)
                }
                
                Spacer()
            }
            
            Text(readinessMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Sleep-Focus Correlation Card
struct SleepFocusCorrelationCard: View {
    let correlation: (lowSleep: Double, highSleep: Double)
    
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
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            if #available(iOS 16.0, *) {
                Chart {
                    BarMark(
                        x: .value("Completion Rate", correlation.lowSleep),
                        y: .value("Sleep", "Less than 6h")
                    )
                    .foregroundStyle(.red.opacity(0.6))
                    
                    BarMark(
                        x: .value("Completion Rate", correlation.highSleep),
                        y: .value("Sleep", "6h or more")
                    )
                    .foregroundStyle(.green.opacity(0.6))
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
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        
                        Text(String(format: "%.0f%%", correlation.lowSleep * 100))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("≥ 6h sleep")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        
                        Text(String(format: "%.0f%%", correlation.highSleep * 100))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            
            if difference > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                    
                    Text("With 6+ hours of sleep, your focus completion rate is \(differencePercent)% higher")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Content Suggestions Card
struct ContentSuggestionsCard: View {
    let suggestions: [(contentId: String, count: Int, suggestion: String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Content Suggestions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.65, green: 0.8, blue: 0.92))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.contentId.capitalized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        
                        Text(suggestion.suggestion)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Activity Balance Card
struct ActivityBalanceCard: View {
    @StateObject private var sessionManager = SessionManager.shared
    
    private var activityDistribution: [(type: String, count: Int, color: Color)] {
        let sleep = sessionManager.sessions(ofType: .sleep, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        let focus = sessionManager.sessions(ofType: .focus, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        let breathing = sessionManager.sessions(ofType: .breathing, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()).count
        
        return [
            (type: "Sleep", count: sleep, color: Color(red: 0.4, green: 0.5, blue: 0.8)),
            (type: "Focus", count: focus, color: Color(red: 0.9, green: 0.6, blue: 0.5)),
            (type: "Breathe", count: breathing, color: Color(red: 0.65, green: 0.8, blue: 0.92))
        ].sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Balance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            Text("Last 30 days")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
            
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
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    CrossFeatureAnalyticsView()
}

