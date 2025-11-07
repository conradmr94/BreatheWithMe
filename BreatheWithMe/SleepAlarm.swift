//
//  SleepAlarm.swift
//  BreatheWithMe
//
//  Represents a scheduled wake-up alarm with snooze and sound metadata.
//

import Foundation

struct SleepAlarm: Identifiable, Codable {
    let id: UUID
    var date: Date
    var isEnabled: Bool
    var label: String?
    var snoozeMinutes: Int
    var sound: String

    init(id: UUID = UUID(), date: Date, isEnabled: Bool, label: String? = nil, snoozeMinutes: Int = 10, sound: String) {
        self.id = id
        self.date = date
        self.isEnabled = isEnabled
        self.label = label
        self.snoozeMinutes = snoozeMinutes
        self.sound = sound
    }
}

