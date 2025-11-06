//
//  AudioEventDetector.swift
//  BreatheWithMe
//
//  Simple on-device audio event detection (snore, talk, cough)
//  Uses energy/bandpass analysis - no cloud API needed
//

import Foundation
import AVFoundation

enum AudioEventType {
    case snore
    case talk
    case cough
    case silence
}

struct AudioEvent {
    let type: AudioEventType
    let start: Date
    let duration: TimeInterval
}

/// Simple audio event detector using energy and frequency analysis
class AudioEventDetector {
    private var audioEngine: AVAudioEngine?
    private var isRecording = false
    private var eventCallbacks: [(AudioEvent) -> Void] = []
    
    // MARK: - Configuration
    
    // Snore detection: 80-300 Hz band, sustained energy
    private let snoreLowFreq: Float = 80.0
    private let snoreHighFreq: Float = 300.0
    private let snoreEnergyThreshold: Float = 0.3
    
    // Speech detection: broader band, higher energy
    private let speechLowFreq: Float = 300.0
    private let speechHighFreq: Float = 3400.0
    private let speechEnergyThreshold: Float = 0.5
    
    // MARK: - Recording
    
    func startRecording(onEventDetected: @escaping (AudioEvent) -> Void) throws {
        guard !isRecording else { return }
        
        eventCallbacks.append(onEventDetected)
        
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        // Configure for low-latency monitoring
        let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }
        
        try engine.start()
        
        self.audioEngine = engine
        self.isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        isRecording = false
        eventCallbacks.removeAll()
    }
    
    // MARK: - Audio Processing
    
    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS energy
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelDataValue[i] * channelDataValue[i]
        }
        let rms = sqrt(sum / Float(frameLength))
        
        // Simple frequency analysis (zero-crossing rate for speech detection)
        var zeroCrossings = 0
        for i in 1..<frameLength {
            if (channelDataValue[i] >= 0) != (channelDataValue[i-1] >= 0) {
                zeroCrossings += 1
            }
        }
        let zcr = Float(zeroCrossings) / Float(frameLength)
        
        // Detect event type
        let eventType: AudioEventType
        
        if rms > speechEnergyThreshold && zcr > 0.1 {
            // High energy + high zero-crossing = likely speech
            eventType = .talk
        } else if rms > snoreEnergyThreshold && zcr < 0.05 {
            // Moderate energy + low zero-crossing = likely snore
            eventType = .snore
        } else if rms > 0.7 {
            // Very high energy spike = possible cough
            eventType = .cough
        } else {
            eventType = .silence
        }
        
        // Only report non-silence events
        if eventType != .silence {
            let event = AudioEvent(
                type: eventType,
                start: Date(),
                duration: Double(buffer.frameLength) / buffer.format.sampleRate
            )
            
            DispatchQueue.main.async {
                for callback in self.eventCallbacks {
                    callback(event)
                }
            }
        }
    }
}

