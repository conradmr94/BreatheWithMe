//
//  SessionManager.swift
//  BreatheWithMe
//
//  Comprehensive session management with rich metadata support
//

import Foundation
import SwiftUI

// MARK: - Enhanced Session Model
struct EnhancedSession: Codable, Identifiable {
    let id: UUID
    let type: SessionType
    let start: Date
    let end: Date
    var meta: SessionMetadata
    
    var durationSeconds: Int {
        Int(end.timeIntervalSince(start))
    }
    
    enum SessionType: String, Codable {
        case sleep, focus, breathing
    }
    
    struct SessionMetadata: Codable {
        // Sleep-specific
        var sleepScore: Int? // 0-100
        var snoreMinutes: Int?
        var wakeups: Int?
        var wasoSeconds: Int? // Wake After Sleep Onset
        var bedtimeRegularity: Bool? // Was bedtime close to usual?
        
        // Focus-specific
        var plannedDuration: Int? // Planned duration in seconds
        var completed: Bool?
        var distractions: Int?
        var tag: String? // Optional tag for focus sessions
        
        // Breathing-specific
        var protocolId: String? // e.g., "478", "box_4_4_4_4", "2_1_exhale"
        var preStressLevel: Int? // 1-5
        var postStressLevel: Int? // 1-5
        
        // Cross-feature
        var contentId: String? // Which sound/content was used
        var contentDuration: Int? // How long content played
        
        init() {
            self.sleepScore = nil
            self.snoreMinutes = nil
            self.wakeups = nil
            self.wasoSeconds = nil
            self.bedtimeRegularity = nil
            self.plannedDuration = nil
            self.completed = nil
            self.distractions = nil
            self.tag = nil
            self.protocolId = nil
            self.preStressLevel = nil
            self.postStressLevel = nil
            self.contentId = nil
            self.contentDuration = nil
        }
    }
    
    init(id: UUID = UUID(), type: SessionType, start: Date, end: Date, meta: SessionMetadata = SessionMetadata()) {
        self.id = id
        self.type = type
        self.start = start
        self.end = end
        self.meta = meta
    }
}

// MARK: - Session Manager
@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @AppStorage("enhancedSessions") private var sessionsData: Data = Data()
    
    private init() {}
    
    // MARK: - Session Storage
    
    var allSessions: [EnhancedSession] {
        if let decoded = try? JSONDecoder().decode([EnhancedSession].self, from: sessionsData) {
            return decoded.sorted { $0.start > $1.start }
        }
        return []
    }
    
    func saveSession(_ session: EnhancedSession) {
        var sessions = allSessions
        sessions.append(session)
        
        // Keep only last 365 days
        let oneYearAgo = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
        sessions = sessions.filter { $0.start >= oneYearAgo }
        
        if let encoded = try? JSONEncoder().encode(sessions) {
            sessionsData = encoded
            objectWillChange.send()
        }
    }
    
    // MARK: - Query Helpers
    
    func sessions(ofType type: EnhancedSession.SessionType, from startDate: Date? = nil, to endDate: Date? = nil) -> [EnhancedSession] {
        var filtered = allSessions.filter { $0.type == type }
        
        if let start = startDate {
            filtered = filtered.filter { $0.start >= start }
        }
        
        if let end = endDate {
            filtered = filtered.filter { $0.start <= end }
        }
        
        return filtered
    }
    
    func sessions(in dateRange: ClosedRange<Date>) -> [EnhancedSession] {
        allSessions.filter { dateRange.contains($0.start) }
    }
    
    // MARK: - Sleep Queries
    
    func sleepSessions(from startDate: Date, to endDate: Date) -> [EnhancedSession] {
        sessions(ofType: .sleep, from: startDate, to: endDate)
    }
    
    func averageSleepScore(days: Int = 7) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = sessions(ofType: .sleep, from: cutoff)
            .compactMap { $0.meta.sleepScore }
        
        guard !recent.isEmpty else { return nil }
        return Double(recent.reduce(0, +)) / Double(recent.count)
    }
    
    func bedtimeRegularity(days: Int = 30) -> (mean: Date, stdDev: TimeInterval)? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = sessions(ofType: .sleep, from: cutoff)
        
        guard !recent.isEmpty else { return nil }
        
        let bedtimes = recent.map { $0.start }
        let meanSeconds = bedtimes.map { Calendar.current.component(.hour, from: $0) * 3600 + Calendar.current.component(.minute, from: $0) * 60 }.reduce(0, +) / bedtimes.count
        
        let meanDate = Calendar.current.date(bySettingHour: meanSeconds / 3600, minute: (meanSeconds % 3600) / 60, second: 0, of: Date()) ?? Date()
        
        let variances = bedtimes.map { abs($0.timeIntervalSince(meanDate)) }
        let variance = variances.reduce(0, +) / Double(variances.count)
        let stdDev = sqrt(variance)
        
        return (mean: meanDate, stdDev: stdDev)
    }
    
    // MARK: - Focus Queries
    
    func focusSessions(from startDate: Date, to endDate: Date) -> [EnhancedSession] {
        sessions(ofType: .focus, from: startDate, to: endDate)
    }
    
    func focusCompletionRate(days: Int = 7) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = sessions(ofType: .focus, from: cutoff)
        
        guard !recent.isEmpty else { return nil }
        
        let completed = recent.filter { $0.meta.completed == true }.count
        return Double(completed) / Double(recent.count)
    }
    
    func bestFocusHours() -> [Int] {
        let recent = sessions(ofType: .focus, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
        
        var hourCounts: [Int: (started: Int, completed: Int)] = [:]
        
        for session in recent {
            let hour = Calendar.current.component(.hour, from: session.start)
            hourCounts[hour, default: (0, 0)].started += 1
            if session.meta.completed == true {
                hourCounts[hour, default: (0, 0)].completed += 1
            }
        }
        
        // Return hours with >80% completion rate, sorted by completion rate
        return hourCounts
            .filter { hour, counts in
                counts.started >= 3 && Double(counts.completed) / Double(counts.started) > 0.8
            }
            .sorted { $0.value.completed > $1.value.completed }
            .prefix(3)
            .map { $0.key }
    }
    
    func recommendedFocusDuration() -> Int? {
        let recent = sessions(ofType: .focus, from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())
            .suffix(10)
        
        guard !recent.isEmpty else { return nil }
        
        let completionRate = Double(recent.filter { $0.meta.completed == true }.count) / Double(recent.count)
        
        if completionRate < 0.6 {
            // Suggest shorter duration
            let avgPlanned = recent.compactMap { $0.meta.plannedDuration }.reduce(0, +) / recent.count
            return max(300, avgPlanned - 300) // Reduce by 5 min, min 5 min
        } else if completionRate > 0.9 {
            // Suggest longer duration
            let avgPlanned = recent.compactMap { $0.meta.plannedDuration }.reduce(0, +) / recent.count
            return min(3600, avgPlanned + 300) // Add 5 min, max 60 min
        }
        
        return nil
    }
    
    // MARK: - Breathing Queries
    
    func breathingSessions(from startDate: Date, to endDate: Date) -> [EnhancedSession] {
        sessions(ofType: .breathing, from: startDate, to: endDate)
    }
    
    func averageStressReduction(days: Int = 7) -> Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = sessions(ofType: .breathing, from: cutoff)
            .filter { $0.meta.preStressLevel != nil && $0.meta.postStressLevel != nil }
        
        guard !recent.isEmpty else { return nil }
        
        let reductions = recent.map { ($0.meta.preStressLevel ?? 0) - ($0.meta.postStressLevel ?? 0) }
        return Double(reductions.reduce(0, +)) / Double(reductions.count)
    }
    
    func breathingStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let uniqueDays = Set(allSessions
            .filter { $0.type == .breathing }
            .map { calendar.startOfDay(for: $0.start) })
        
        let sortedDays = uniqueDays.sorted(by: >)
        
        guard !sortedDays.isEmpty else { return 0 }
        
        // Check if there's activity today or yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard sortedDays[0] == today || sortedDays[0] == yesterday else { return 0 }
        
        var streak = 0
        var checkDate = today
        
        for _ in 0..<365 {
            if uniqueDays.contains(checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Cross-Feature Queries
    
    func sleepFocusCorrelation(days: Int = 30) -> (lowSleep: Double, highSleep: Double)? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Group by day
        let calendar = Calendar.current
        var daySleep: [Date: Int] = [:] // sleep duration in seconds
        var dayFocus: [Date: (started: Int, completed: Int)] = [:]
        
        for session in allSessions.filter({ $0.start >= cutoff }) {
            let day = calendar.startOfDay(for: session.start)
            
            if session.type == .sleep {
                daySleep[day, default: 0] += session.durationSeconds
            } else if session.type == .focus {
                let current = dayFocus[day, default: (0, 0)]
                dayFocus[day] = (current.started + 1, current.completed + (session.meta.completed == true ? 1 : 0))
            }
        }
        
        // Compare days with <6h sleep vs >=6h
        var lowSleepCompletions: [Double] = []
        var highSleepCompletions: [Double] = []
        
        for (day, focus) in dayFocus {
            guard let sleepDuration = daySleep[day], focus.started > 0 else { continue }
            let completionRate = Double(focus.completed) / Double(focus.started)
            
            if sleepDuration < 6 * 3600 {
                lowSleepCompletions.append(completionRate)
            } else {
                highSleepCompletions.append(completionRate)
            }
        }
        
        guard !lowSleepCompletions.isEmpty && !highSleepCompletions.isEmpty else { return nil }
        
        let lowAvg = lowSleepCompletions.reduce(0, +) / Double(lowSleepCompletions.count)
        let highAvg = highSleepCompletions.reduce(0, +) / Double(highSleepCompletions.count)
        
        return (lowSleep: lowAvg, highSleep: highAvg)
    }
    
    func dailyReadiness() -> String {
        guard let sleepScore = averageSleepScore(days: 3) else {
            return "Normal"
        }
        
        if sleepScore > 80 {
            return "Push"
        } else if sleepScore > 60 {
            return "Normal"
        } else {
            return "Light"
        }
    }
    
    func contentSuggestions() -> [(contentId: String, count: Int, suggestion: String)] {
        let recent = allSessions
            .filter { $0.start >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date() }
            .compactMap { session -> (String, Int)? in
                guard let contentId = session.meta.contentId else { return nil }
                return (contentId, session.meta.contentDuration ?? session.durationSeconds)
            }
        
        var contentUsage: [String: (count: Int, totalDuration: Int)] = [:]
        for (id, duration) in recent {
            let current = contentUsage[id, default: (0, 0)]
            contentUsage[id] = (current.count + 1, current.totalDuration + duration)
        }
        
        return contentUsage
            .filter { $0.value.count >= 5 }
            .map { id, usage in
                let suggestion = "You used \(id) \(usage.count) times. Want to add it to bedtime?"
                return (contentId: id, count: usage.count, suggestion: suggestion)
            }
    }
}

