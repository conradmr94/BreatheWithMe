//
//  WalkStatsView.swift
//  BreatheWithMe
//
//  Mirrors the style of Focus/Breathe/Sleep stats for the Walk feature.
//

import SwiftUI

// MARK: - Data Model
struct WalkStats: Codable {
    var walkSessionsCompleted: Int = 0
    var totalWalkingTimeSeconds: Int = 0
    var totalDistanceMeters: Double = 0
    var totalSteps: Int = 0
    var longestWalkSeconds: Int = 0
    var bestPaceSecondsPerKm: Int = 0
    
    var totalWalkingTimeFormatted: String {
        Self.formatTime(totalWalkingTimeSeconds)
    }
    
    var averageWalkDurationSeconds: Int {
        guard walkSessionsCompleted > 0 else { return 0 }
        return totalWalkingTimeSeconds / walkSessionsCompleted
    }
    
    var averageWalkDurationFormatted: String {
        Self.formatTime(averageWalkDurationSeconds)
    }
    
    var totalDistanceFormatted: String {
        Self.formatDistance(totalDistanceMeters)
    }
    
    var averageDistanceFormatted: String {
        guard walkSessionsCompleted > 0 else { return "0 km" }
        let avgMeters = totalDistanceMeters / Double(walkSessionsCompleted)
        return Self.formatDistance(avgMeters)
    }
    
    var bestPaceFormatted: String {
        guard bestPaceSecondsPerKm > 0 else { return "—" }
        let minutes = bestPaceSecondsPerKm / 60
        let seconds = bestPaceSecondsPerKm % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    static func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remaining = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, remaining)
        } else {
            return "\(remaining)s"
        }
    }
    
    static func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.2f km", km)
    }
}

struct WalkStatsView: View {
    @AppStorage("walkStats") private var walkStatsData: Data = Data()
    @StateObject private var sessionManager = SessionManager.shared
    
    private var walkStats: WalkStats {
        if let decoded = try? JSONDecoder().decode(WalkStats.self, from: walkStatsData) {
            return decoded
        }
        return WalkStats()
    }
    
    private var walksThisWeek: (count: Int, duration: Int, distanceMeters: Double, steps: Int) {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return (0, 0, 0, 0)
        }
        
        let sessions = sessionManager.walkSessions(from: weekStart, to: now)
        let totalDuration = sessions.reduce(0) { $0 + $1.durationSeconds }
        let totalDistance = sessions.reduce(0.0) { $0 + ($1.meta.distanceMeters ?? 0) }
        let totalSteps = sessions.reduce(0) { $0 + ($1.meta.steps ?? 0) }
        
        return (sessions.count, totalDuration, totalDistance, totalSteps)
    }
    
    private var accentColor: Color {
        Color(red: 0.32, green: 0.72, blue: 0.55)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Walk Stats")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
                    Text("Your mindful walking insights")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                }
                .padding(.top, 8)
                
                // Overview Card
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Walk Sessions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("\(walkStats.walkSessionsCompleted)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Walk Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text(walkStats.totalWalkingTimeFormatted)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Distance")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text(walkStats.totalDistanceFormatted)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Steps")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("\(walkStats.totalSteps)")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
                
                // Averages
                if walkStats.walkSessionsCompleted > 0 {
                    VStack(spacing: 14) {
                        StatRow(icon: "timer", title: "Avg Duration", value: walkStats.averageWalkDurationFormatted)
                        StatRow(icon: "map", title: "Avg Distance", value: walkStats.averageDistanceFormatted)
                        StatRow(icon: "speedometer", title: "Best Pace", value: walkStats.bestPaceFormatted)
                        StatRow(icon: "figure.walk.motion", title: "Longest Walk", value: walkStats.longestWalkSeconds > 0 ? WalkStats.formatTime(walkStats.longestWalkSeconds) : "—")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                }
                
                // This Week Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("This Week")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                    
                    HStack {
                        Text("Sessions")
                        Spacer()
                        Text("\(walksThisWeek.count)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    HStack {
                        Text("Time Walked")
                        Spacer()
                        Text(walksThisWeek.duration > 0 ? WalkStats.formatTime(walksThisWeek.duration) : "—")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    HStack {
                        Text("Distance")
                        Spacer()
                        Text(walksThisWeek.distanceMeters > 0 ? WalkStats.formatDistance(walksThisWeek.distanceMeters) : "—")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    HStack {
                        Text("Steps")
                        Spacer()
                        Text(walksThisWeek.steps > 0 ? "\(walksThisWeek.steps)" : "—")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.55))
                .frame(maxWidth: 360)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                )
            }
            .padding(.bottom, 28)
        }
        .background(Color(red: 0.95, green: 0.97, blue: 0.99).ignoresSafeArea())
    }
}

// MARK: - Reusable Row
private struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.32, green: 0.72, blue: 0.55))
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.55))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
        }
    }
}

#Preview {
    WalkStatsView()
}
