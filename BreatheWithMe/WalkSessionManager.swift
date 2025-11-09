//
//  WalkSessionManager.swift
//  BreatheWithMe
//
//

import Foundation
import CoreMotion
import CoreLocation
import Combine
import SwiftUI

// MARK: - Walk Stats Model
struct WalkStats: Codable {
    var walkSessionsCompleted: Int
    var totalWalkingTimeSeconds: Int
    var totalDistanceMeters: Double
    var totalSteps: Double
    var totalCaloriesBurned: Double
    var totalStressReliefScore: Double
    var stressSampleCount: Int
    var longestWalkSeconds: Int
    var lastUpdated: Date
    
    init(
        walkSessionsCompleted: Int = 0,
        totalWalkingTimeSeconds: Int = 0,
        totalDistanceMeters: Double = 0,
        totalSteps: Double = 0,
        totalCaloriesBurned: Double = 0,
        totalStressReliefScore: Double = 0,
        stressSampleCount: Int = 0,
        longestWalkSeconds: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.walkSessionsCompleted = walkSessionsCompleted
        self.totalWalkingTimeSeconds = totalWalkingTimeSeconds
        self.totalDistanceMeters = totalDistanceMeters
        self.totalSteps = totalSteps
        self.totalCaloriesBurned = totalCaloriesBurned
        self.totalStressReliefScore = totalStressReliefScore
        self.stressSampleCount = stressSampleCount
        self.longestWalkSeconds = longestWalkSeconds
        self.lastUpdated = lastUpdated
    }
    
    private enum CodingKeys: String, CodingKey {
        case walkSessionsCompleted
        case totalWalkingTimeSeconds
        case totalDistanceMeters
        case totalSteps
        case totalCaloriesBurned
        case totalStressReliefScore
        case stressSampleCount
        case longestWalkSeconds
        case lastUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        walkSessionsCompleted = try container.decodeIfPresent(Int.self, forKey: .walkSessionsCompleted) ?? 0
        totalWalkingTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .totalWalkingTimeSeconds) ?? 0
        totalDistanceMeters = try container.decodeIfPresent(Double.self, forKey: .totalDistanceMeters) ?? 0
        totalSteps = try container.decodeIfPresent(Double.self, forKey: .totalSteps) ?? 0
        totalCaloriesBurned = try container.decodeIfPresent(Double.self, forKey: .totalCaloriesBurned) ?? 0
        totalStressReliefScore = try container.decodeIfPresent(Double.self, forKey: .totalStressReliefScore) ?? 0
        stressSampleCount = try container.decodeIfPresent(Int.self, forKey: .stressSampleCount) ?? 0
        longestWalkSeconds = try container.decodeIfPresent(Int.self, forKey: .longestWalkSeconds) ?? 0
        lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(walkSessionsCompleted, forKey: .walkSessionsCompleted)
        try container.encode(totalWalkingTimeSeconds, forKey: .totalWalkingTimeSeconds)
        try container.encode(totalDistanceMeters, forKey: .totalDistanceMeters)
        try container.encode(totalSteps, forKey: .totalSteps)
        try container.encode(totalCaloriesBurned, forKey: .totalCaloriesBurned)
        try container.encode(totalStressReliefScore, forKey: .totalStressReliefScore)
        try container.encode(stressSampleCount, forKey: .stressSampleCount)
        try container.encode(longestWalkSeconds, forKey: .longestWalkSeconds)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
    
    var totalDistanceKilometers: Double {
        totalDistanceMeters / 1_000.0
    }
    
    var totalDistanceMiles: Double {
        totalDistanceMeters / 1_609.34
    }
    
    var totalCaloriesKcal: Double {
        totalCaloriesBurned
    }
    
    var averageWalkDurationSeconds: Int {
        guard walkSessionsCompleted > 0 else { return 0 }
        return totalWalkingTimeSeconds / walkSessionsCompleted
    }
    
    var averageDistanceMeters: Double {
        guard walkSessionsCompleted > 0 else { return 0 }
        return totalDistanceMeters / Double(walkSessionsCompleted)
    }
    
    var averageStepsPerWalk: Double {
        guard walkSessionsCompleted > 0 else { return 0 }
        return totalSteps / Double(walkSessionsCompleted)
    }
    
    var averageCaloriesPerWalk: Double {
        guard walkSessionsCompleted > 0 else { return 0 }
        return totalCaloriesBurned / Double(walkSessionsCompleted)
    }
    
    var averageStressReliefScore: Double {
        guard stressSampleCount > 0 else { return 0 }
        return totalStressReliefScore / Double(stressSampleCount)
    }
    
    func formattedTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    var totalTimeFormatted: String {
        formattedTime(totalWalkingTimeSeconds)
    }
    
    var longestWalkFormatted: String {
        formattedTime(longestWalkSeconds)
    }
    
    var averageWalkDurationFormatted: String {
        formattedTime(averageWalkDurationSeconds)
    }
    
    var totalStepsFormatted: String {
        WalkStats.integerFormatter.string(from: NSNumber(value: Int(totalSteps))) ?? "0"
    }
    
    var totalCaloriesFormatted: String {
        WalkStats.integerFormatter.string(from: NSNumber(value: Int(totalCaloriesBurned.rounded()))) ?? "0"
    }
    
    var averageCaloriesFormatted: String {
        WalkStats.integerFormatter.string(from: NSNumber(value: Int(averageCaloriesPerWalk.rounded()))) ?? "0"
    }
    
    var averageStressFormatted: String {
        averageStressReliefScore > 0 ? String(format: "%.0f", averageStressReliefScore) : "--"
    }
    
    private static let integerFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

// MARK: - Breathing Patterns
enum WalkBreathingPattern: String, CaseIterable, Identifiable {
    case coherent
    case box
    case fourSevenEight
    case natural
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .coherent: return "5-5 Coherent"
        case .box: return "4-4-4-4 Box"
        case .fourSevenEight: return "4-7-8 Calm"
        case .natural: return "Natural Flow"
        }
    }
    
    var guidance: String {
        switch self {
        case .coherent: return "Inhale for 5 seconds, exhale for 5 seconds."
        case .box: return "Inhale, hold, exhale, hold – all for 4 seconds."
        case .fourSevenEight: return "Inhale for 4, hold 7, exhale 8 seconds."
        case .natural: return "Match your breath with your steps."
        }
    }
    
    var cycleDuration: Double {
        switch self {
        case .coherent: return 10 // 5 in + 5 out
        case .box: return 16 // 4 + 4 + 4 + 4
        case .fourSevenEight: return 19 // 4 + 7 + 8
        case .natural: return 8
        }
    }
    
    func normalizedScale(at time: TimeInterval) -> CGFloat {
        let progress = time.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
        // Smooth sinusoidal breathing curve
        let value = 0.5 + 0.5 * sin(progress * 2 * .pi - (.pi / 2))
        return CGFloat(0.75 + value * 0.35)
    }
}

@MainActor
final class WalkSessionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = WalkSessionManager()
    
    static var motionUnavailableForUI: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return !CMPedometer.isStepCountingAvailable()
        #endif
    }
    
    // Publishers
    @Published var isWalking: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var steps: Int = 0
    @Published var distanceMeters: Double = 0
    @Published var currentPace: Double? // meters per second
    @Published var route: [CLLocationCoordinate2D] = []
    @Published var currentLocation: CLLocation?
    @Published var authorizationDenied: Bool = false
    @Published var currentPattern: WalkBreathingPattern = .coherent
    @Published var motionUnavailable: Bool = WalkSessionManager.motionUnavailableForUI
    @Published var caloriesBurned: Double = 0
    @Published var stressReliefScore: Double = 0

    @AppStorage("walkStats") private var walkStatsData: Data = Data()
    
    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var sessionStartDate: Date?
    private var lastLocation: CLLocation?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    // MARK: Stats Accessors
    var walkStats: WalkStats {
        get {
            if let decoded = try? JSONDecoder().decode(WalkStats.self, from: walkStatsData) {
                return decoded
            }
            return WalkStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                walkStatsData = encoded
            }
        }
    }
    
    // MARK: - Session Control
    @MainActor
    func startSession() {
        guard !isWalking else { return }
        
        requestLocationAuthorization()
        motionUnavailable = WalkSessionManager.motionUnavailableForUI
        
        sessionStartDate = Date()
        elapsedSeconds = 0
        steps = 0
        distanceMeters = 0
        currentPace = nil
        caloriesBurned = 0
        stressReliefScore = 0
        route.removeAll()
        lastLocation = nil
        authorizationDenied = false
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: sessionStartDate!) { [weak self] data, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        print("Pedometer error: \(error.localizedDescription)")
                        return
                    }
                    if let pedometerData = data {
                        self.steps = pedometerData.numberOfSteps.intValue
                        if let distance = pedometerData.distance?.doubleValue {
                            self.distanceMeters = max(distance, self.distanceMeters)
                        }
                        if let pace = pedometerData.currentPace?.doubleValue {
                            self.currentPace = pace
                        } else if self.elapsedSeconds > 0 && self.distanceMeters > 0 {
                            self.currentPace = self.distanceMeters / Double(self.elapsedSeconds)
                        }
                        self.updateDerivedMetrics()
                    }
                }
            }
        }
        
        locationManager.startUpdatingLocation()
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleTimerTick), userInfo: nil, repeats: true)
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        isWalking = true
    }
    
    @MainActor
    func stopSession(save: Bool = true) {
        guard isWalking else { return }
        
        isWalking = false
        pedometer.stopUpdates()
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        
        if save {
            finalizeSession()
        }
    }
    
    @MainActor
    func resetSession() {
        stopSession(save: false)
        elapsedSeconds = 0
        steps = 0
        distanceMeters = 0
        currentPace = nil
        caloriesBurned = 0
        stressReliefScore = 0
        route.removeAll()
        currentLocation = nil
        lastLocation = nil
        motionUnavailable = WalkSessionManager.motionUnavailableForUI
    }
    
    // MARK: - CLLocationManagerDelegate
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            Task { @MainActor in
                self.authorizationDenied = false
                self.motionUnavailable = WalkSessionManager.motionUnavailableForUI
            }
        case .denied, .restricted:
            Task { @MainActor in
                self.authorizationDenied = true
            }
        default:
            break
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            for location in locations {
                guard location.horizontalAccuracy <= 50 else { continue }
                currentLocation = location
                route.append(location.coordinate)
                
                if let lastLocation = lastLocation {
                    let delta = location.distance(from: lastLocation)
                    if CMPedometer.isDistanceAvailable() == false {
                        distanceMeters += delta
                    }
                }
                lastLocation = location
                updateDerivedMetrics()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    // MARK: - Helpers
    var distanceKilometers: Double {
        distanceMeters / 1_000.0
    }
    
    var distanceMiles: Double {
        distanceMeters / 1_609.34
    }
    
    var durationFormatted: String {
        formatTime(seconds: elapsedSeconds)
    }
    
    var paceText: String {
        guard let pace = currentPace, pace > 0 else { return "--" }
        let minutesPerKilometer = (1 / pace) * 1_000 / 60
        let minutes = Int(minutesPerKilometer)
        let seconds = Int((minutesPerKilometer - Double(minutes)) * 60)
        return String(format: "%d:%02d min/km", minutes, seconds)
    }
    
    var isMetricsAvailable: Bool {
        steps > 0 || distanceMeters > 0 || elapsedSeconds > 0
    }
    
    private func updateDerivedMetrics() {
        caloriesBurned = WalkSessionManager.estimatedCalories(forSteps: steps, distanceMeters: distanceMeters)
        stressReliefScore = WalkSessionManager.stressReliefScore(forSteps: steps, durationSeconds: elapsedSeconds)
    }
    
    static func estimatedCalories(forSteps steps: Int, distanceMeters: Double) -> Double {
        let distanceKilometers = distanceMeters / 1_000.0
        let distanceEstimate = distanceKilometers * 55.0 // ~55 kcal per km for moderate pace
        let stepEstimate = Double(steps) * 0.04 // ~40 kcal per 1000 steps fallback
        return max(distanceEstimate, stepEstimate)
    }
    
    static func estimatedDuration(fromSteps steps: Int) -> Int {
        guard steps > 0 else { return 0 }
        // Average walking cadence ~105 steps per minute
        return Int((Double(steps) / 105.0) * 60.0)
    }
    
    static func stressReliefScore(forSteps steps: Int, durationSeconds: Int) -> Double {
        guard steps > 0 || durationSeconds > 0 else { return 0 }
        let stepScore = min(1.0, Double(steps) / 4_000.0)
        let durationScore = min(1.0, Double(durationSeconds) / 2_700.0) // ~45 minutes
        return (stepScore * 0.6 + durationScore * 0.4) * 100
    }
    
    @MainActor
    private func finalizeSession() {
        guard let startDate = sessionStartDate else { return }
        updateDerivedMetrics()
        let duration = max(elapsedSeconds, Int(Date().timeIntervalSince(startDate)))
        guard duration >= 30 else { return } // ignore very short walks
        
        var stats = walkStats
        stats.walkSessionsCompleted += 1
        stats.totalWalkingTimeSeconds += duration
        stats.totalDistanceMeters += distanceMeters
        stats.totalSteps += Double(steps)
        stats.totalCaloriesBurned += caloriesBurned
        stats.totalStressReliefScore += stressReliefScore
        if stressReliefScore > 0 { stats.stressSampleCount += 1 }
        stats.longestWalkSeconds = max(stats.longestWalkSeconds, duration)
        stats.lastUpdated = Date()
        walkStats = stats
        
        let userStats = UserStatsManager()
        userStats.recordSession(activityType: .walk, durationSeconds: duration)
        
        var metadata = EnhancedSession.SessionMetadata()
        metadata.steps = steps
        metadata.distanceMeters = distanceMeters
        metadata.caloriesBurned = caloriesBurned
        metadata.stressReliefScore = stressReliefScore
        let session = EnhancedSession(type: .walk, start: startDate, end: Date(), meta: metadata)
        SessionManager.shared.saveSession(session)
        
        sessionStartDate = nil
    }
    
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, remainingSeconds)
        } else {
            return "\(seconds)s"
        }
    }
    
    @MainActor
    func requestLocationAuthorization() {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            authorizationDenied = true
        default:
            authorizationDenied = false
        }
    }
    
    @objc private func handleTimerTick() {
        elapsedSeconds += 1
        if distanceMeters > 0 && elapsedSeconds > 0 {
            currentPace = distanceMeters / Double(elapsedSeconds)
        }
        updateDerivedMetrics()
    }
}

