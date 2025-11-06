//
//  BreathingProtocols.swift
//  BreatheWithMe
//
//  Breathing protocol definitions (4-7-8, box, 2:1 exhale, etc.)
//

import Foundation

struct BreathingProtocol: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let inhaleSeconds: Double
    let holdSeconds: Double
    let exhaleSeconds: Double
    
    static let allProtocols: [BreathingProtocol] = [
        BreathingProtocol(
            id: "478",
            name: "4-7-8",
            description: "Inhale 4s, hold 7s, exhale 8s. Calms the nervous system.",
            inhaleSeconds: 4.0,
            holdSeconds: 7.0,
            exhaleSeconds: 8.0
        ),
        BreathingProtocol(
            id: "box_4_4_4_4",
            name: "Box Breathing",
            description: "Equal 4s phases: inhale, hold, exhale, hold. Used by Navy SEALs.",
            inhaleSeconds: 4.0,
            holdSeconds: 4.0,
            exhaleSeconds: 4.0
        ),
        BreathingProtocol(
            id: "box_5_5_5_5",
            name: "Box 5-5-5-5",
            description: "Box breathing with 5-second phases.",
            inhaleSeconds: 5.0,
            holdSeconds: 5.0,
            exhaleSeconds: 5.0
        ),
        BreathingProtocol(
            id: "2_1_exhale",
            name: "2:1 Exhale",
            description: "Exhale twice as long as inhale. Promotes relaxation.",
            inhaleSeconds: 4.0,
            holdSeconds: 0.0,
            exhaleSeconds: 8.0
        ),
        BreathingProtocol(
            id: "equal",
            name: "Equal Breathing",
            description: "Simple equal inhale and exhale.",
            inhaleSeconds: 4.0,
            holdSeconds: 0.0,
            exhaleSeconds: 4.0
        )
    ]
    
    static func findProtocol(withId id: String) -> BreathingProtocol? {
        allProtocols.first { $0.id == id }
    }
}

