//
//  UserStatsManager.swift
//  BreatheWithMe
//
//  Manages aggregated user statistics across all app activities
//

import Foundation
import SwiftUI

// MARK: - Session History Model
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let activityType: ActivityType
    let durationSeconds: Int
    
    enum ActivityType: String, Codable {
        case breathe = "Breathe"
        case focus = "Focus"
        case rest = "Rest"
        case sleep = "Sleep"
    }
    
    init(id: UUID = UUID(), date: Date = Date(), activityType: ActivityType, durationSeconds: Int) {
        self.id = id
        self.date = date
        self.activityType = activityType
        self.durationSeconds = durationSeconds
    }
}

// MARK: - User Stats Manager
class UserStatsManager: ObservableObject {
    // AppStorage for persistent data
    @AppStorage("breatheStats") private var breatheStatsData: Data = Data()
    @AppStorage("focusStats") private var focusStatsData: Data = Data()
    @AppStorage("sessionHistory") private var sessionHistoryData: Data = Data()
    @AppStorage("lastActivityDate") private var lastActivityDateString: String = ""
    
    // MARK: - Computed Properties
    
    /// Get BreatheStats from storage
    var breatheStats: BreatheStats {
        if let decoded = try? JSONDecoder().decode(BreatheStats.self, from: breatheStatsData) {
            return decoded
        }
        return BreatheStats()
    }
    
    /// Get FocusStats from storage
    var focusStats: FocusStats {
        if let decoded = try? JSONDecoder().decode(FocusStats.self, from: focusStatsData) {
            return decoded
        }
        return FocusStats()
    }
    
    /// Get SleepStats from storage
    @AppStorage("sleepStats") private var sleepStatsData: Data = Data()
    var sleepStats: SleepStats {
        if let decoded = try? JSONDecoder().decode(SleepStats.self, from: sleepStatsData) {
            return decoded
        }
        return SleepStats()
    }
    
    /// Get session history from storage
    var sessionHistory: [SessionRecord] {
        if let decoded = try? JSONDecoder().decode([SessionRecord].self, from: sessionHistoryData) {
            return decoded
        }
        return []
    }
    
    /// Last activity date
    var lastActivityDate: Date? {
        guard !lastActivityDateString.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: lastActivityDateString)
    }
    
    // MARK: - Aggregate Stats
    
    /// Total sessions completed across all activities
    var totalSessions: Int {
        breatheStats.sessionsCompleted + 
        focusStats.focusSessionsCompleted + 
        sleepStats.sleepSessionsCompleted
    }
    
    /// Total time spent across all activities (in seconds)
    var totalTimeSeconds: Int {
        breatheStats.totalTimeSeconds + 
        focusStats.totalFocusTimeSeconds + 
        focusStats.totalRestTimeSeconds +
        sleepStats.totalSleepTimeSeconds
    }
    
    /// Formatted total time
    var totalTimeFormatted: String {
        formatTime(seconds: totalTimeSeconds)
    }
    
    /// Current streak (consecutive days with at least one session)
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    /// Longest streak ever achieved
    var longestStreak: Int {
        calculateLongestStreak()
    }
    
    /// Total number of unique days with activity
    var totalActiveDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    /// Most used activity type
    var favoriteActivity: String {
        // Count sessions by type from session history
        let breatheCount = sessionHistory.filter { $0.activityType == .breathe }.count
        let focusCount = sessionHistory.filter { $0.activityType == .focus }.count
        let sleepCount = sessionHistory.filter { $0.activityType == .sleep }.count
        
        // Handle no sessions case
        if breatheCount == 0 && focusCount == 0 && sleepCount == 0 {
            return "None yet"
        }
        
        // Find the activity with the most sessions
        let maxCount = max(breatheCount, focusCount, sleepCount)
        
        // Check if multiple activities are tied for first place
        let topActivities = [
            (name: "Breathe", count: breatheCount),
            (name: "Focus", count: focusCount),
            (name: "Sleep", count: sleepCount)
        ].filter { $0.count == maxCount }
        
        // If all three are equal (or two are tied at the top)
        if topActivities.count > 1 {
            return "Balanced"
        }
        
        // Return the single top activity
        return topActivities.first?.name ?? "None yet"
    }
    
    /// Average session duration in seconds
    var averageSessionDuration: Int {
        guard totalSessions > 0 else { return 0 }
        return totalTimeSeconds / totalSessions
    }
    
    /// Average session duration formatted
    var averageSessionDurationFormatted: String {
        formatTime(seconds: averageSessionDuration)
    }
    
    // MARK: - Recent Activity
    
    /// Sessions from the last 7 days
    var recentSessions: [SessionRecord] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessionHistory.filter { $0.date >= sevenDaysAgo }
    }
    
    /// Number of sessions this week
    var sessionsThisWeek: Int {
        recentSessions.count
    }
    
    // MARK: - Helper Methods
    
    /// Record a new session (this should be called when a session completes)
    func recordSession(activityType: SessionRecord.ActivityType, durationSeconds: Int) {
        var history = sessionHistory
        let newRecord = SessionRecord(
            date: Date(),
            activityType: activityType,
            durationSeconds: durationSeconds
        )
        history.append(newRecord)
        
        // Keep only last 365 days of history to prevent excessive storage
        let oneYearAgo = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        history = history.filter { $0.date >= oneYearAgo }
        
        // Save to storage
        if let encoded = try? JSONEncoder().encode(history) {
            sessionHistoryData = encoded
        }
        
        // Update last activity date
        let formatter = ISO8601DateFormatter()
        lastActivityDateString = formatter.string(from: Date())
        
        // Trigger UI update
        objectWillChange.send()
    }
    
    /// Calculate current streak
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get unique days with sessions, sorted descending
        let uniqueDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted(by: >)
        
        guard !sortedDays.isEmpty else { return 0 }
        
        // Check if there's activity today or yesterday (to be lenient)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard sortedDays[0] == today || sortedDays[0] == yesterday else { return 0 }
        
        var streak = 0
        var checkDate = today
        
        // Count consecutive days backwards from today
        for _ in 0..<365 { // Max 365 days to prevent infinite loop
            if uniqueDays.contains(checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Calculate longest streak ever
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        
        // Get unique days with sessions, sorted ascending
        let uniqueDays = Set(sessionHistory.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted()
        
        guard !sortedDays.isEmpty else { return 0 }
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDays.count {
            let daysDiff = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // Streak broken
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    /// Format time in a human-readable way
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "\(secs)s"
        }
    }
    
    /// Get time of day greeting
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    /// Days since last activity
    var daysSinceLastActivity: Int? {
        guard let lastDate = lastActivityDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastDate, to: Date())
        return components.day
    }
    
    /// Motivational message based on usage
    var motivationalMessage: String {
        return "One session at a time."
    }
}

