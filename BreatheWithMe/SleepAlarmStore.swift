//
//  SleepAlarmStore.swift
//  BreatheWithMe
//
//  Lightweight persistence layer for the user's sleep alarm.
//

import Foundation

final class SleepAlarmStore {
    static let shared = SleepAlarmStore()

    private let storageKey = "sleepAlarm_v1"
    private let defaults = UserDefaults.standard

    private init() {}

    func load() -> SleepAlarm? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(SleepAlarm.self, from: data)
    }

    func save(_ alarm: SleepAlarm) {
        if let data = try? JSONEncoder().encode(alarm) {
            defaults.set(data, forKey: storageKey)
        }
    }

    func update(_ transform: (inout SleepAlarm) -> Void) {
        guard var alarm = load() else { return }
        transform(&alarm)
        save(alarm)
    }

    func delete() {
        defaults.removeObject(forKey: storageKey)
    }
}

