//
//  FocusAnalyticsView.swift
//  BreatheWithMe
//
//  Comprehensive focus analytics and performance insights
//

import SwiftUI
import Charts

struct FocusAnalyticsView: View {
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
                
                // Completion Rate Card
                if let rate = completionRate {
                    CompletionRateCard(rate: rate, sessions: focusSessions)
                }
                
                // Time-of-Day Performance
                if !focusSessions.isEmpty {
                    TimeOfDayPerformanceChart(sessions: focusSessions)
                }
                
                // Adaptive Recommendation
                if let recommendation = recommendedDuration {
                    AdaptiveRecommendationCard(recommendedDuration: recommendation)
                }
                
                // Distraction Tracking
                if !focusSessions.isEmpty {
                    DistractionCard(sessions: focusSessions)
                }
                
                // Session Duration Trends
                if !focusSessions.isEmpty {
                    FocusDurationChart(sessions: focusSessions)
                }
                
                // Summary Stats
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

// MARK: - Completion Rate Card
struct CompletionRateCard: View {
    let rate: Double
    let sessions: [EnhancedSession]
    
    private var rateColor: Color {
        if rate >= 0.8 {
            return .green
        } else if rate >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var completedCount: Int {
        sessions.filter { $0.meta.completed == true }.count
    }
    
    private var totalCount: Int {
        sessions.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Rate")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(Int(rate * 100))%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(rateColor)
                
                Text("\(completedCount)/\(totalCount) sessions")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.9, green: 0.9, blue: 0.9))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(rateColor)
                        .frame(width: geometry.size.width * CGFloat(rate))
                }
            }
            .frame(height: 8)
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

// MARK: - Time-of-Day Performance Chart
struct TimeOfDayPerformanceChart: View {
    let sessions: [EnhancedSession]
    
    private var hourlyData: [(hour: Int, started: Int, completed: Int)] {
        var hourStats: [Int: (started: Int, completed: Int)] = [:]
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.start)
            let current = hourStats[hour, default: (0, 0)]
            hourStats[hour] = (current.started + 1, current.completed + (session.meta.completed == true ? 1 : 0))
        }
        
        return hourStats.map { (hour: $0.key, started: $0.value.started, completed: $0.value.completed) }
            .sorted { $0.hour < $1.hour }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time-of-Day Performance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            if #available(iOS 16.0, *) {
                Chart(hourlyData, id: \.hour) { data in
                    BarMark(
                        x: .value("Hour", data.hour),
                        y: .value("Sessions", data.started)
                    )
                    .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.5).opacity(0.3))
                    
                    BarMark(
                        x: .value("Hour", data.hour),
                        y: .value("Completed", data.completed)
                    )
                    .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.5))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: 1)) { value in
                        AxisGridLine()
                        if let hour = value.as(Int.self), hour % 3 == 0 {
                            AxisValueLabel {
                                Text("\(hour):00")
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS 15
                SimpleBarChart(data: hourlyData.map { Double($0.completed) })
                    .frame(height: 200)
            }
            
            HStack(spacing: 16) {
                LegendItem(color: Color(red: 0.9, green: 0.6, blue: 0.5), label: "Completed")
                LegendItem(color: Color(red: 0.9, green: 0.6, blue: 0.5).opacity(0.3), label: "Started")
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

// MARK: - Adaptive Recommendation Card
struct AdaptiveRecommendationCard: View {
    let recommendedDuration: Int
    
    private var durationString: String {
        let minutes = recommendedDuration / 60
        return "\(minutes) min"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.5))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Try \(durationString)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                
                Text("Based on your recent completion rate")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.9, green: 0.6, blue: 0.5).opacity(0.1))
        )
    }
}

// MARK: - Distraction Card
struct DistractionCard: View {
    let sessions: [EnhancedSession]
    
    private var totalDistractions: Int {
        sessions.compactMap { $0.meta.distractions }.reduce(0, +)
    }
    
    private var averageDistractions: Double {
        let distractionCounts = sessions.compactMap { $0.meta.distractions }
        guard !distractionCounts.isEmpty else { return 0 }
        return Double(distractionCounts.reduce(0, +)) / Double(distractionCounts.count)
    }
    
    private var totalFocusTime: Int {
        sessions.reduce(0) { $0 + $1.durationSeconds }
    }
    
    private var distractionRate: Double {
        guard totalFocusTime > 0 else { return 0 }
        return Double(totalDistractions) / (Double(totalFocusTime) / 3600.0) // per hour
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distraction Tracking")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(averageDistractions))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.5))
                    Text("avg per session")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", distractionRate))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.5))
                    Text("per hour")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                }
                
                Spacer()
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

// MARK: - Focus Duration Chart
struct FocusDurationChart: View {
    let sessions: [EnhancedSession]
    
    private var chartData: [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        var dayTotals: [Date: Int] = [:]
        
        for session in sessions {
            let day = calendar.startOfDay(for: session.start)
            dayTotals[day, default: 0] += session.durationSeconds
        }
        
        return dayTotals.map { (date: $0.key, minutes: Double($0.value) / 60.0) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Focus Time Trend")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            
            if #available(iOS 16.0, *) {
                Chart(chartData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Minutes", dataPoint.minutes)
                    )
                    .foregroundStyle(Color(red: 0.9, green: 0.6, blue: 0.5))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date, unit: .day),
                        y: .value("Minutes", dataPoint.minutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.9, green: 0.6, blue: 0.5).opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartData.count > 14 ? 2 : 1)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            } else {
                SimpleLineChart(data: chartData.map { $0.minutes })
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

// MARK: - Focus Summary Stats
struct FocusSummaryStats: View {
    let sessions: [EnhancedSession]
    
    private var totalFocusMinutes: Double {
        Double(sessions.reduce(0) { $0 + $1.durationSeconds }) / 60.0
    }
    
    private var averageSessionMinutes: Double {
        guard !sessions.isEmpty else { return 0 }
        return totalFocusMinutes / Double(sessions.count)
    }
    
    private var completedSessions: Int {
        sessions.filter { $0.meta.completed == true }.count
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Focus",
                    value: String(format: "%.0fm", totalFocusMinutes),
                    icon: "timer"
                )
                
                StatCard(
                    title: "Avg Session",
                    value: String(format: "%.0fm", averageSessionMinutes),
                    icon: "clock.fill"
                )
                
                StatCard(
                    title: "Completed",
                    value: "\(completedSessions)",
                    icon: "checkmark.circle.fill"
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

// MARK: - Helper Views
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
        }
    }
}

struct SimpleLineChart: View {
    let data: [Double]
    
    private var maxValue: Double {
        data.max() ?? 1.0
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let stepX = geometry.size.width / CGFloat(max(data.count - 1, 1))
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height * (1.0 - CGFloat(value / maxValue))
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color(red: 0.9, green: 0.6, blue: 0.5), lineWidth: 2)
        }
    }
}

#Preview {
    FocusAnalyticsView()
}

