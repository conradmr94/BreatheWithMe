//
//  SleepScoreCalculator.swift
//  BreatheWithMe
//
//  Rule-based sleep score calculation (0-100)
//

import Foundation

struct SleepScoreCalculator {
    // MARK: - Sleep Score Calculation
    
    /// Calculate sleep score (0-100) based on duration, regularity, and disturbances
    static func calculateScore(
        durationSeconds: Int,
        goalDurationSeconds: Int = 8 * 3600, // Default 8 hours
        bedtimeRegularity: Bool = false,
        wakeups: Int = 0,
        wasoSeconds: Int = 0 // Wake After Sleep Onset
    ) -> Int {
        var score = 0
        
        // Duration component (0-60 points)
        let durationRatio = min(1.0, Double(durationSeconds) / Double(goalDurationSeconds))
        score += Int(durationRatio * 60)
        
        // Regularity bonus (0-15 points)
        if bedtimeRegularity {
            score += 15
        }
        
        // Disturbance penalties
        // Each wakeup costs 2 points (max -10)
        let wakeupPenalty = min(10, wakeups * 2)
        score -= wakeupPenalty
        
        // WASO penalty: >30 min = -5, >60 min = -10
        let wasoMinutes = wasoSeconds / 60
        if wasoMinutes > 60 {
            score -= 10
        } else if wasoMinutes > 30 {
            score -= 5
        }
        
        // Clamp to 0-100
        return max(0, min(100, score))
    }
    
    /// Calculate bedtime regularity (was bedtime within 30 min of usual?)
    static func isBedtimeRegular(
        currentBedtime: Date,
        historicalBedtimes: [Date],
        toleranceMinutes: Int = 30
    ) -> Bool {
        guard !historicalBedtimes.isEmpty else { return false }
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentBedtime)
        let currentMinutes = (currentComponents.hour ?? 0) * 60 + (currentComponents.minute ?? 0)
        
        let historicalMinutes = historicalBedtimes.map { bedtime in
            let components = calendar.dateComponents([.hour, .minute], from: bedtime)
            return (components.hour ?? 0) * 60 + (components.minute ?? 0)
        }
        
        let avgMinutes = historicalMinutes.reduce(0, +) / historicalMinutes.count
        
        return abs(currentMinutes - avgMinutes) <= toleranceMinutes
    }
}

