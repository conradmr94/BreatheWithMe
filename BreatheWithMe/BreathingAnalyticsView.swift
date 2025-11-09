//
//  BreathingAnalyticsView.swift
//  BreatheWithMe
//
//  Comprehensive breathing analytics and insights
//

import SwiftUI
import Charts

struct BreathingAnalyticsView: View {
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
                
                // Streak Card
                StreakCard(streak: currentStreak)
                
                // Stress Reduction Card
                if let reduction = averageStressReduction {
                    StressReductionCard(reduction: reduction, sessions: breathingSessions)
                }
                
                // Protocol Usage
                if !breathingSessions.isEmpty {
                    ProtocolUsageChart(sessions: breathingSessions)
                }
                
                // Session Frequency
                if !breathingSessions.isEmpty {
                    BreathingFrequencyChart(sessions: breathingSessions)
                }
                
                // Summary Stats
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
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(streak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(Color(red: 0.65, green: 0.8, blue: 0.92))
                    
                    Text("day streak")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
                
                Spacer()
            }
            
            if streak > 0 {
                Text("Keep it up! 🎉")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Start your streak today!")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - Stress Reduction Card
struct StressReductionCard: View {
    let reduction: Double
    let sessions: [EnhancedSession]
    
    private var reductionColor: Color {
        if reduction >= 1.5 {
            return .green
        } else if reduction >= 1.0 {
            return Color(red: 0.65, green: 0.8, blue: 0.92)
        } else {
            return .orange
        }
    }
    
    private var sessionsWithStressData: [EnhancedSession] {
        sessions.filter { $0.meta.preStressLevel != nil && $0.meta.postStressLevel != nil }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Stress Reduction")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", reduction))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(reductionColor)
                
                Text("points")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
            }
            
            Text("Based on \(sessionsWithStressData.count) sessions with stress ratings")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6).opacity(0.8))
            
            // Stress reduction breakdown
            if !sessionsWithStressData.isEmpty {
                let reductions = sessionsWithStressData.map {
                    ($0.meta.preStressLevel ?? 0) - ($0.meta.postStressLevel ?? 0)
                }
                
                let significant = reductions.filter { $0 >= 2 }.count
                let moderate = reductions.filter { $0 >= 1 && $0 < 2 }.count
                let minimal = reductions.filter { $0 < 1 }.count
                
                HStack(spacing: 16) {
                    StatBadge(label: "Significant", count: significant, color: .green)
                    StatBadge(label: "Moderate", count: moderate, color: Color(red: 0.65, green: 0.8, blue: 0.92))
                    StatBadge(label: "Minimal", count: minimal, color: .orange)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Protocol Usage Chart
struct ProtocolUsageChart: View {
    let sessions: [EnhancedSession]
    
    private var protocolCounts: [(protocolId: String, count: Int)] {
        var counts: [String: Int] = [:]
        
        for session in sessions {
            if let protocolId = session.meta.protocolId {
                counts[protocolId, default: 0] += 1
            } else {
                counts["standard", default: 0] += 1
            }
        }
        
        return counts.map { (protocolId: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    private func protocolName(for id: String) -> String {
        if let breathingProtocol = BreathingProtocol.findProtocol(withId: id) {
            return breathingProtocol.name
        }
        return id.capitalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protocol Usage")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            if #available(iOS 16.0, *) {
                Chart(protocolCounts, id: \.protocolId) { data in
                    BarMark(
                        x: .value("Count", data.count),
                        y: .value("Protocol", protocolName(for: data.protocolId))
                    )
                    .foregroundStyle(Color(red: 0.65, green: 0.8, blue: 0.92))
                    .cornerRadius(4)
                }
                .frame(height: CGFloat(protocolCounts.count * 40))
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                // Fallback for iOS 15
                VStack(spacing: 12) {
                    ForEach(protocolCounts, id: \.protocolId) { data in
                        HStack {
                            Text(protocolName(for: data.protocolId))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            
                            Spacer()
                            
                            Text("\(data.count)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.65, green: 0.8, blue: 0.92))
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

// MARK: - Breathing Frequency Chart
struct BreathingFrequencyChart: View {
    let sessions: [EnhancedSession]
    
    private var chartData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        var dayCounts: [Date: Int] = [:]
        
        for session in sessions {
            let day = calendar.startOfDay(for: session.start)
            dayCounts[day, default: 0] += 1
        }
        
        return dayCounts.map { (date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Frequency")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            if #available(iOS 16.0, *) {
                Chart(chartData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Sessions", dataPoint.count)
                    )
                    .foregroundStyle(Color(red: 0.65, green: 0.8, blue: 0.92))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartData.count > 14 ? 2 : 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                SimpleBarChart(data: chartData.map { Double($0.count) })
                    .frame(height: 200)
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

// MARK: - Breathing Summary Stats
struct BreathingSummaryStats: View {
    let sessions: [EnhancedSession]
    
    private var totalMinutes: Double {
        Double(sessions.reduce(0) { $0 + $1.durationSeconds }) / 60.0
    }
    
    private var averageSessionMinutes: Double {
        guard !sessions.isEmpty else { return 0 }
        return totalMinutes / Double(sessions.count)
    }
    
    private var sessionsWithProtocols: Int {
        sessions.filter { $0.meta.protocolId != nil }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Time",
                    value: String(format: "%.0fm", totalMinutes),
                    icon: "wind"
                )
                
                StatCard(
                    title: "Avg Session",
                    value: String(format: "%.0fm", averageSessionMinutes),
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Sessions",
                    value: "\(sessions.count)",
                    icon: "circle.fill"
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

#Preview {
    BreathingAnalyticsView()
}
