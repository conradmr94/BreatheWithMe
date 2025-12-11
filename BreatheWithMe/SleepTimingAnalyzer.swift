//
//  SleepTimingAnalyzer.swift
//  BreatheWithMe
//
//  Analyze sleep timing patterns and consistency
//

import Foundation

class SleepTimingAnalyzer {
    
    // MARK: - Bedtime Consistency
    
    /// Calculate bedtime consistency (standard deviation in seconds)
    static func bedtimeConsistency(sessions: [EnhancedSession]) -> TimeInterval {
        guard sessions.count >= 2 else { return 0 }
        
        let calendar = Calendar.current
        let bedtimes = sessions.map { $0.start }
        
        // Convert to seconds from midnight for comparison
        let secondsFromMidnight = bedtimes.map { date -> Int in
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            let second = calendar.component(.second, from: date)
            return hour * 3600 + minute * 60 + second
        }
        
        let mean = Double(secondsFromMidnight.reduce(0, +)) / Double(secondsFromMidnight.count)
        let variances = secondsFromMidnight.map { pow(Double($0) - mean, 2) }
        let variance = variances.reduce(0, +) / Double(variances.count)
        
        return sqrt(variance)
    }
    
    // MARK: - Duration Consistency
    
    /// Calculate sleep duration consistency (standard deviation in seconds)
    static func durationConsistency(sessions: [EnhancedSession]) -> TimeInterval {
        guard sessions.count >= 2 else { return 0 }
        
        let durations = sessions.map { Double($0.durationSeconds) }
        let mean = durations.reduce(0, +) / Double(durations.count)
        
        let variances = durations.map { pow($0 - mean, 2) }
        let variance = variances.reduce(0, +) / Double(variances.count)
        
        return sqrt(variance)
    }
    
    // MARK: - Optimal Duration
    
    /// Check if duration is in the optimal 7-9 hour range
    static func isOptimalDuration(_ seconds: Int) -> Bool {
        let hours = Double(seconds) / 3600.0
        return hours >= 7.0 && hours <= 9.0
    }
    
    // MARK: - Circadian Score
    
    /// Calculate circadian alignment score (0-100)
    /// Earlier bedtimes (10pm-12am) score higher
    static func circadianScore(bedtime: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: bedtime)
        let minute = calendar.component(.minute, from: bedtime)
        
        // Convert to total minutes from midnight
        let minutesFromMidnight = hour * 60 + minute
        
        // Optimal range: 22:00 (10pm) to 23:00 (11pm) = 100 points
        // Good range: 21:00-22:00 or 23:00-24:00 = 80-100 points
        // Acceptable: 20:00-21:00 or 00:00-01:00 = 60-80 points
        // Poor: Before 20:00 or after 01:00 = 0-60 points
        
        if minutesFromMidnight >= 22 * 60 && minutesFromMidnight < 23 * 60 {
            // 10pm-11pm: optimal
            return 100.0
        } else if (minutesFromMidnight >= 21 * 60 && minutesFromMidnight < 22 * 60) ||
                  (minutesFromMidnight >= 23 * 60 && minutesFromMidnight < 24 * 60) {
            // 9pm-10pm or 11pm-12am: good
            return 85.0
        } else if (minutesFromMidnight >= 20 * 60 && minutesFromMidnight < 21 * 60) ||
                  (minutesFromMidnight >= 0 && minutesFromMidnight < 1 * 60) {
            // 8pm-9pm or 12am-1am: acceptable
            return 70.0
        } else if minutesFromMidnight >= 1 * 60 && minutesFromMidnight < 3 * 60 {
            // 1am-3am: late
            return 50.0
        } else if minutesFromMidnight >= 3 * 60 && minutesFromMidnight < 6 * 60 {
            // 3am-6am: very late
            return 30.0
        } else {
            // Very early (6am-8pm)
            return 40.0
        }
    }
    
    // MARK: - Insights
    
    /// Generate actionable timing insights
    static func generateTimingInsights(sessions: [EnhancedSession]) -> [String] {
        guard !sessions.isEmpty else { return ["No sleep data available yet."] }
        
        var insights: [String] = []
        
        // Check bedtime consistency
        if sessions.count >= 7 {
            let consistency = bedtimeConsistency(sessions: sessions)
            let consistencyMinutes = Int(consistency / 60)
            
            if consistencyMinutes < 30 {
                insights.append("Excellent bedtime consistency! You go to sleep around the same time.")
            } else if consistencyMinutes < 60 {
                insights.append("Good bedtime consistency. Try to maintain your sleep schedule.")
            } else {
                insights.append("Your bedtime varies by \(consistencyMinutes) minutes. A consistent schedule improves sleep quality.")
            }
        }
        
        // Check duration consistency
        if sessions.count >= 7 {
            let durationStdDev = durationConsistency(sessions: sessions)
            let durationMinutes = Int(durationStdDev / 60)
            
            if durationMinutes < 45 {
                insights.append("Your sleep duration is very consistent.")
            } else {
                insights.append("Your sleep duration varies significantly. Aim for 7-9 hours consistently.")
            }
        }
        
        // Check circadian alignment
        let recentSessions = Array(sessions.prefix(7))
        let avgCircadian = recentSessions.map { circadianScore(bedtime: $0.start) }
            .reduce(0, +) / Double(recentSessions.count)
        
        if avgCircadian >= 85 {
            insights.append("Great! You're going to bed at an optimal time for your circadian rhythm.")
        } else if avgCircadian >= 70 {
            insights.append("Your bedtime is good. Going to bed earlier (10-11pm) may improve sleep quality.")
        } else {
            insights.append("Try going to bed between 10-11pm for better alignment with your natural sleep cycle.")
        }
        
        // Check optimal duration
        let optimalCount = sessions.filter { isOptimalDuration($0.durationSeconds) }.count
        let optimalPercentage = Double(optimalCount) / Double(sessions.count) * 100
        
        if optimalPercentage >= 80 {
            insights.append("You're consistently getting 7-9 hours of sleep. Keep it up!")
        } else if optimalPercentage >= 50 {
            insights.append("Try to hit 7-9 hours of sleep more consistently.")
        } else {
            insights.append("Aim for 7-9 hours of sleep per night for optimal health.")
        }
        
        return insights
    }
}

