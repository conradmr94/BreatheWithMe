//
//  SleepViewModel.swift
//  BreatheWithMe
//
//  Created by Matthew R Conrad on 10/22/25.
//

import Foundation
import HealthKit

@MainActor
final class SleepViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var summaries: [SleepDaySummary] = []
    @Published var lastError: String?

    private let hk = HealthKitManager.shared
    private let calendar = Calendar.current

    func onAppear() {
        Task {
            do {
                try await hk.requestAuthorization()
                isAuthorized = true
                await reloadLast14Days()
                hk.startSleepObserver { [weak self] in
                    Task { await self?.reloadLast14Days() }
                }
            } catch {
                lastError = error.localizedDescription
            }
        }
    }

    func reloadLast14Days() async {
        guard isAuthorized else { return }
        let now = Date()
        guard let start = calendar.date(byAdding: .day, value: -14, to: now) else { return }
        do {
            let samples = try await hk.fetchSleep(from: start, to: now)
            let grouped = groupSamplesBySleepDay(samples: samples)
            let list = grouped
                .sorted { $0.key > $1.key }
                .map { (day, samples) -> SleepDaySummary in
                    var stageBuckets: [SleepStage: Int] = [:]
                    var total = 0
                    for s in samples {
                        let secs = Int(s.endDate.timeIntervalSince(s.startDate))
                        total += secs
                        let stage = SleepStage(rawValue: s.value)
                        stageBuckets[stage, default: 0] += secs
                    }
                    return SleepDaySummary(date: day, totalSeconds: total, stageSeconds: stageBuckets)
                }
            summaries = list
        } catch {
            lastError = error.localizedDescription
        }
    }

    // Group each sample by the calendar day of its *end* date (typical for sleep that crosses midnight).
    private func groupSamplesBySleepDay(samples: [HKCategorySample]) -> [Date: [HKCategorySample]] {
        var out: [Date: [HKCategorySample]] = [:]
        for s in samples {
            let day = calendar.startOfDay(for: s.endDate)
            out[day, default: []].append(s)
        }
        return out
    }

    var lastNight: SleepDaySummary? { summaries.first }
    var rollingAvgHours14: Double {
        guard !summaries.isEmpty else { return 0 }
        let total = summaries.reduce(0) { $0 + $1.totalSeconds }
        return Double(total) / Double(summaries.count) / 3600.0
    }

    func formatHours(_ h: Double) -> String {
        String(format: "%.1f h", h)
    }

    func formatDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: d)
    }
}
