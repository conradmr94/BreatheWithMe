//
//  HealthKitManager.swift
//  BreatheWithMe
//
//  Created by Matthew R Conrad on 10/22/25.
//

import Foundation
import HealthKit

enum SleepStage: CaseIterable {
    case awake, core, deep, rem, unknown

    init(rawValue: Int) {
        guard let v = HKCategoryValueSleepAnalysis(rawValue: rawValue) else {
            self = .unknown
            return
        }

        switch v {
        case .inBed:
            // Older apps used this to represent "time spent in bed" rather than actual sleep.
            // We can treat it as .awake for simplicity, or bucket it separately if you wish.
            self = .awake
        case .awake:
            self = .awake
        case .asleepUnspecified:
            self = .core // bucket unspecified as light/core
        case .asleepCore:
            self = .core
        case .asleepDeep:
            self = .deep
        case .asleepREM:
            self = .rem
        @unknown default:
            self = .unknown
        }
    }
    var label: String {
        switch self {
        case .awake: return "Awake"
        case .core:  return "Core"
        case .deep:  return "Deep"
        case .rem:   return "REM"
        case .unknown: return "Unknown"
        }
    }
}

struct SleepDaySummary: Identifiable, Hashable {
    let id = UUID()
    let date: Date               // “sleep day” (uses end date’s day)
    let totalSeconds: Int
    let stageSeconds: [SleepStage: Int]

    var totalHours: Double { Double(totalSeconds) / 3600.0 }

    func stageHours(_ stage: SleepStage) -> Double {
        Double(stageSeconds[stage] ?? 0) / 3600.0
    }
}

/// Thin wrapper around HKHealthStore for sleep reads + background updates.
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private var sleepType: HKCategoryType {
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    }
    private var respiratoryRateType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    }
    private var mindfulType: HKCategoryType {
        HKObjectType.categoryType(forIdentifier: .mindfulSession)!
    }
    private var stepCountType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    }
    private var walkingDistanceType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    }
    private var activeEnergyType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    }
    private var heartRateType: HKQuantityType {
        HKObjectType.quantityType(forIdentifier: .heartRate)!
    }

    // MARK: Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitAccessError.unavailable
        }
        let shareTypes: Set<HKSampleType> = [mindfulType]
        let readTypes: Set<HKObjectType> = [
            sleepType,
            respiratoryRateType,
            mindfulType,
            stepCountType,
            walkingDistanceType,
            activeEnergyType,
            heartRateType
        ]
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            if store.authorizationStatus(for: stepCountType) == .sharingDenied {
                throw HealthKitAccessError.authorizationDenied
            }
        } catch let error as HKError {
            switch error.code {
            case .errorHealthDataUnavailable:
                throw HealthKitAccessError.unavailable
            case .errorHealthDataRestricted:
                throw HealthKitAccessError.authorizationRestricted
            case .errorAuthorizationDenied:
                throw HealthKitAccessError.authorizationDenied
            case .errorAuthorizationNotDetermined:
                throw HealthKitAccessError.authorizationNotDetermined
            default:
                throw HealthKitAccessError.underlying(error)
            }
        } catch {
            throw HealthKitAccessError.underlying(error)
        }
    }

    // MARK: Fetch window
    func fetchSleep(from start: Date, to end: Date) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { cont in
            let q = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error = error { cont.resume(throwing: error); return }
                cont.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            self.store.execute(q)
        }
    }

    // MARK: Background delivery
    func startSleepObserver(onChange: @escaping () -> Void) {
        let observer = HKObserverQuery(sampleType: sleepType, predicate: nil) { _, _, error in
            guard error == nil else { return }
            onChange()
        }
        store.execute(observer)
        store.enableBackgroundDelivery(for: sleepType, frequency: .hourly) { _, _ in }
    }
    
    // MARK: - Walking & Activity Metrics
    private func sumQuantity(_ type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let quantity = statistics?.sumQuantity() {
                    continuation.resume(returning: quantity.doubleValue(for: unit))
                } else {
                    continuation.resume(returning: 0)
                }
            }
            store.execute(query)
        }
    }
    
    private func averageQuantity(_ type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let quantity = statistics?.averageQuantity() {
                    continuation.resume(returning: quantity.doubleValue(for: unit))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
    }
    
    func stepCount(for interval: DateInterval) async throws -> Double {
        try await sumQuantity(stepCountType, unit: HKUnit.count(), start: interval.start, end: interval.end)
    }
    
    func walkingDistance(for interval: DateInterval) async throws -> Double {
        try await sumQuantity(walkingDistanceType, unit: HKUnit.meter(), start: interval.start, end: interval.end)
    }
    
    func activeEnergy(for interval: DateInterval) async throws -> Double {
        try await sumQuantity(activeEnergyType, unit: HKUnit.kilocalorie(), start: interval.start, end: interval.end)
    }
    
    func averageHeartRate(for interval: DateInterval) async throws -> Double? {
        try await averageQuantity(heartRateType, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), start: interval.start, end: interval.end)
    }
    
    func todayStepCount() async throws -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let interval = DateInterval(start: start, duration: 60 * 60 * 24)
        return try await stepCount(for: interval)
    }
    
    func todayWalkingDistance() async throws -> Double {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let interval = DateInterval(start: start, end: Date())
        return try await walkingDistance(for: interval)
    }
    
    func recentStepHistory(days: Int) async throws -> [(date: Date, steps: Double)] {
        let calendar = Calendar.current
        var results: [(Date, Double)] = []
        
        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            let interval = DateInterval(start: start, end: end)
            let steps = try await stepCount(for: interval)
            results.append((start, steps))
        }
        
        return results.sorted { $0.0 < $1.0 }
    }
    
    // MARK: - Sleep Event Analysis
    
    /// Extract wakeups and WASO from HealthKit sleep samples for a given time range
    func analyzeSleepEvents(from start: Date, to end: Date) async throws -> (wakeups: Int, wasoSeconds: Int) {
        let samples = try await fetchSleep(from: start, to: end)
        
        // Sort by start time
        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }
        
        // Count wakeups (each awake segment after the first sleep segment is a wakeup)
        var wakeupCount = 0
        var hasSlept = false
        
        for sample in sortedSamples {
            let stage = SleepStage(rawValue: sample.value)
            if stage == .awake && hasSlept {
                // This is a wakeup after sleep has started
                wakeupCount += 1
            } else if stage != .awake && stage != .unknown {
                // Sleep has started
                hasSlept = true
            }
        }
        
        // Calculate WASO (Wake After Sleep Onset) - total awake time after first sleep
        var wasoTotal: TimeInterval = 0
        var firstSleepTime: Date?
        
        for sample in sortedSamples {
            let stage = SleepStage(rawValue: sample.value)
            
            if firstSleepTime == nil && stage != .awake && stage != .unknown {
                firstSleepTime = sample.startDate
            }
            
            if let sleepStart = firstSleepTime, stage == .awake {
                // This awake segment is after sleep onset
                let awakeStart = max(sample.startDate, sleepStart)
                let awakeEnd = sample.endDate
                if awakeEnd > sleepStart {
                    wasoTotal += awakeEnd.timeIntervalSince(awakeStart)
                }
            }
        }
        
        return (wakeups: wakeupCount, wasoSeconds: Int(wasoTotal))
    }

    // MARK: - Respiratory Rate

    func fetchRespiratoryRates(from start: Date, to end: Date) async throws -> [HKQuantitySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: respiratoryRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: (samples as? [HKQuantitySample]) ?? [])
                }
            }
            store.execute(query)
        }
    }

    func latestRespiratoryRateSample() async throws -> HKQuantitySample? {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { cont in
            let query = HKSampleQuery(sampleType: respiratoryRateType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: (samples as? [HKQuantitySample])?.first)
                }
            }
            store.execute(query)
        }
    }

    // MARK: - Mindful Minutes

    func saveMindfulSession(start: Date, end: Date) async throws {
        guard start < end else { return }
        // Mindful sessions use a single "mindful" value (0)
        let sample = HKCategorySample(type: mindfulType, value: 0, start: start, end: end)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            store.save(sample) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save mindful session"]))
                }
            }
        }
    }

    func fetchMindfulSessions(from start: Date, to end: Date) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
                }
            }
            store.execute(query)
        }
    }

    func mindfulMinutesTotal(from start: Date, to end: Date) async throws -> Double {
        let sessions = try await fetchMindfulSessions(from: start, to: end)
        let totalSeconds = sessions.reduce(0.0) { partial, sample in
            partial + sample.endDate.timeIntervalSince(sample.startDate)
        }
        return totalSeconds / 60.0
    }
}

enum HealthKitAccessError: LocalizedError {
    case unavailable
    case authorizationDenied
    case authorizationRestricted
    case authorizationNotDetermined
    case underlying(Error)
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Health data isn’t available on this device. HealthKit requires a physical iPhone or Apple Watch."
        case .authorizationDenied:
            return "Health permissions were denied. Open Settings › Health › Data Access to allow BreatheWithMe to read your activity data."
        case .authorizationRestricted:
            return "Health permissions are restricted on this device."
        case .authorizationNotDetermined:
            return "Health permissions haven’t been granted yet."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}
