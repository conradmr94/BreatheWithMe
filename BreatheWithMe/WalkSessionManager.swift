//
//  WalkSessionManager.swift
//  BreatheWithMe
//
//  Lightweight manager to start/stop walk sessions, persist walk stats,
//  and send enhanced sessions to SessionManager.
//

import Foundation
import SwiftUI

@MainActor
final class WalkSessionManager: ObservableObject {
    static let shared = WalkSessionManager()
    
    @AppStorage("walkStats") private var walkStatsData: Data = Data()
    
    @Published private(set) var isWalking: Bool = false
    @Published private(set) var sessionStart: Date?
    @Published private(set) var plannedDuration: Int? // seconds
    
    private init() {}
    
    // MARK: - Session Control
    
    func startWalk(plannedDuration: Int? = nil) {
        guard !isWalking else { return }
        sessionStart = Date()
        self.plannedDuration = plannedDuration
        isWalking = true
    }
    
    func cancelWalk() {
        resetState()
    }
    
    /// Complete the walk and persist stats + session history.
    /// - Parameters:
    ///   - steps: Optional step count measured for the session
    ///   - distanceMeters: Optional distance walked in meters
    ///   - caloriesBurned: Optional calories burned
    ///   - stressReliefScore: Optional stress relief score (0-100)
    ///   - contentId: Optional content/sound identifier used
    ///   - contentDuration: Optional content playback time in seconds
    ///   - route: Optional array of coordinates representing the walk route
    func completeWalk(
        steps: Int? = nil,
        distanceMeters: Double? = nil,
        caloriesBurned: Double? = nil,
        stressReliefScore: Double? = nil,
        contentId: String? = nil,
        contentDuration: Int? = nil,
        route: [EnhancedSession.Coordinate]? = nil
    ) {
        guard let start = sessionStart else { return }
        let end = Date()
        let duration = max(0, Int(end.timeIntervalSince(start)))
        
        // Update local walk stats
        updateWalkStats(
            durationSeconds: duration,
            steps: steps,
            distanceMeters: distanceMeters
        )
        
        // Track in UserStatsManager for streaks and cross-feature totals
        let userStatsManager = UserStatsManager()
        userStatsManager.recordSession(activityType: .walk, durationSeconds: duration)
        
        // Persist enhanced session for analytics
        var meta = EnhancedSession.SessionMetadata()
        meta.plannedDuration = plannedDuration
        meta.completed = true
        meta.steps = steps
        meta.distanceMeters = distanceMeters
        meta.caloriesBurned = caloriesBurned
        meta.stressReliefScore = stressReliefScore
        meta.contentId = contentId
        meta.contentDuration = contentDuration ?? duration
        
        // Store route data if available
        if let route = route, !route.isEmpty {
            meta.route = route
        }
        
        let session = EnhancedSession(
            type: .walk,
            start: start,
            end: end,
            meta: meta
        )
        SessionManager.shared.saveSession(session)
        
        resetState()
    }
    
    // MARK: - Internal Helpers
    
    private func resetState() {
        isWalking = false
        sessionStart = nil
        plannedDuration = nil
    }
    
    private func updateWalkStats(
        durationSeconds: Int,
        steps: Int?,
        distanceMeters: Double?
    ) {
        guard durationSeconds > 0 else { return }
        
        var stats: WalkStats
        if let decoded = try? JSONDecoder().decode(WalkStats.self, from: walkStatsData) {
            stats = decoded
        } else {
            stats = WalkStats()
        }
        
        stats.walkSessionsCompleted += 1
        stats.totalWalkingTimeSeconds += durationSeconds
        
        if let steps = steps {
            stats.totalSteps += steps
        }
        
        if let distanceMeters = distanceMeters {
            stats.totalDistanceMeters += distanceMeters
            
            // Derive best pace if distance is non-zero
            let distanceKm = distanceMeters / 1000.0
            if distanceKm > 0 {
                let paceSecondsPerKm = Int(Double(durationSeconds) / distanceKm)
                if stats.bestPaceSecondsPerKm == 0 || paceSecondsPerKm < stats.bestPaceSecondsPerKm {
                    stats.bestPaceSecondsPerKm = paceSecondsPerKm
                }
            }
        }
        
        if durationSeconds > stats.longestWalkSeconds {
            stats.longestWalkSeconds = durationSeconds
        }
        
        if let encoded = try? JSONEncoder().encode(stats) {
            walkStatsData = encoded
        }
    }
}
