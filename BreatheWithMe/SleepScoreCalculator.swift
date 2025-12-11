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
    
    // MARK: - Enhanced Sleep Score with Self-Reports
    
    /// Calculate enhanced sleep score (0-100) incorporating self-reported metrics and objective data
    /// Weighting:
    /// - 35% Self-reported quality/rest
    /// - 20% Duration (7-9 hours optimal)
    /// - 15% Bedtime consistency
    /// - 10% Minimal phone interactions
    /// - 10% Low snooze count
    /// - 10% Minimal wakeups/WASO
    static func calculateEnhancedScore(
        durationSeconds: Int,
        selfReportedQuality: Int?,
        selfReportedRest: Int?,
        bedtimeConsistency: Bool,
        snoozeCount: Int,
        phoneInteractions: Int,
        wakeups: Int,
        wasoSeconds: Int
    ) -> Int {
        var totalScore = 0.0
        
        // 1. Self-reported quality and rest (35% total = 17.5% each)
        if let quality = selfReportedQuality {
            // Scale 1-5 to 0-100, then apply 17.5% weight
            let qualityScore = Double(quality - 1) / 4.0 * 100.0 // Convert 1-5 to 0-100
            totalScore += qualityScore * 0.175
        }
        
        if let rest = selfReportedRest {
            // Scale 1-5 to 0-100, then apply 17.5% weight
            let restScore = Double(rest - 1) / 4.0 * 100.0
            totalScore += restScore * 0.175
        }
        
        // If we don't have self-reports, redistribute their weight to other factors
        let selfReportWeight = (selfReportedQuality != nil ? 0.175 : 0.0) +
                               (selfReportedRest != nil ? 0.175 : 0.0)
        let redistributedWeight = 0.35 - selfReportWeight
        
        // 2. Duration score (20% + redistributed)
        let durationHours = Double(durationSeconds) / 3600.0
        let durationScore: Double
        if durationHours >= 7.0 && durationHours <= 9.0 {
            durationScore = 100.0 // Optimal
        } else if durationHours >= 6.0 && durationHours < 7.0 {
            durationScore = 70.0 + (durationHours - 6.0) * 30.0 // 70-100
        } else if durationHours >= 9.0 && durationHours <= 10.0 {
            durationScore = 100.0 - (durationHours - 9.0) * 20.0 // 100-80
        } else if durationHours >= 5.0 && durationHours < 6.0 {
            durationScore = 40.0 + (durationHours - 5.0) * 30.0 // 40-70
        } else if durationHours > 10.0 && durationHours <= 12.0 {
            durationScore = 80.0 - (durationHours - 10.0) * 20.0 // 80-40
        } else {
            durationScore = max(0, min(40.0, durationHours * 8.0)) // Less than 5 hours
        }
        totalScore += durationScore * (0.20 + redistributedWeight / 4)
        
        // 3. Bedtime consistency (15% + redistributed)
        let consistencyScore = bedtimeConsistency ? 100.0 : 50.0
        totalScore += consistencyScore * (0.15 + redistributedWeight / 4)
        
        // 4. Phone interactions (10% + redistributed)
        let phoneScore: Double
        if phoneInteractions == 0 {
            phoneScore = 100.0
        } else if phoneInteractions <= 2 {
            phoneScore = 80.0
        } else if phoneInteractions <= 5 {
            phoneScore = 50.0
        } else {
            phoneScore = max(0, 50.0 - Double(phoneInteractions - 5) * 10.0)
        }
        totalScore += phoneScore * (0.10 + redistributedWeight / 4)
        
        // 5. Snooze count (10% + redistributed)
        let snoozeScore: Double
        if snoozeCount == 0 {
            snoozeScore = 100.0
        } else if snoozeCount == 1 {
            snoozeScore = 80.0
        } else if snoozeCount == 2 {
            snoozeScore = 60.0
        } else {
            snoozeScore = max(0, 60.0 - Double(snoozeCount - 2) * 20.0)
        }
        totalScore += snoozeScore * (0.10 + redistributedWeight / 4)
        
        // 6. Wakeups and WASO (10%)
        let disturbanceScore: Double
        let wasoMinutes = wasoSeconds / 60
        
        if wakeups == 0 && wasoMinutes == 0 {
            disturbanceScore = 100.0
        } else {
            var score = 100.0
            // Penalize wakeups (each costs 10 points)
            score -= Double(wakeups) * 10.0
            // Penalize WASO
            if wasoMinutes > 60 {
                score -= 30.0
            } else if wasoMinutes > 30 {
                score -= 15.0
            } else if wasoMinutes > 15 {
                score -= 5.0
            }
            disturbanceScore = max(0, score)
        }
        totalScore += disturbanceScore * 0.10
        
        // Clamp final score to 0-100
        return Int(max(0, min(100, totalScore)))
    }
}

