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

    // MARK: Authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data not available"])
        }
        try await store.requestAuthorization(toShare: [], read: [sleepType])
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
}
