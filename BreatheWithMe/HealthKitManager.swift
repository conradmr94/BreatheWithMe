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

    // MARK: Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"])
        }
        try await store.requestAuthorization(toShare: [], read: [sleepType, respiratoryRateType])
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
}
