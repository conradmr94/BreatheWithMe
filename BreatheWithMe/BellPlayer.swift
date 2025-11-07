//
//  BellPlayer.swift
//  BreatheWithMe
//

import Foundation
import AVFoundation
import AudioToolbox

final class BellPlayer {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        // Note: Audio session will be configured by AlarmManager when alarm starts
        // This is just for initial setup - AlarmManager will override it
        
        audioEngine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        // Connect main mixer to output node
        audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: format)
        
        audioEngine.prepare()
    }
    
    func playBell() {
        // Ensure audio session is active (AlarmManager should have configured it)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Force activate the audio session for alarm playback
            try audioSession.setActive(true, options: [])
            print("✅ BellPlayer: Audio session activated")
        } catch {
            print("⚠️ BellPlayer: Failed to activate audio session: \(error)")
        }
        
        // Ensure audio engine is running
        if !audioEngine.isRunning {
            print("⚠️ BellPlayer: Audio engine not running, restarting...")
            do {
                // Reconnect player node if needed
                if !audioEngine.attachedNodes.contains(playerNode) {
                    audioEngine.attach(playerNode)
                    let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
                    audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
                    audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: format)
                    print("✅ BellPlayer: Player node reconnected")
                }
                try audioEngine.start()
                print("✅ BellPlayer: Audio engine restarted")
            } catch {
                print("❌ BellPlayer: Failed to restart audio engine: \(error)")
                // Fallback to system sound if engine fails
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                AudioServicesPlaySystemSound(1005) // System alert sound
                return
            }
        }
        
        // Set main mixer output volume to maximum for alarm
        audioEngine.mainMixerNode.outputVolume = 1.0
        
        let sampleRate: Double = 44100.0
        let duration: Double = 3.5
        let fundamentalFreq: Double = 180.0
        let volume: Float = 0.25  // Much quieter bell for transitions
        
        let frameCount = Int(duration * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            print("❌ BellPlayer: Failed to create audio format")
            AudioServicesPlaySystemSound(1005) // Fallback
            return
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            print("❌ BellPlayer: Failed to create audio buffer")
            AudioServicesPlaySystemSound(1005) // Fallback
            return
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        guard let channelData = buffer.floatChannelData?[0] else {
            print("❌ BellPlayer: Failed to get channel data")
            AudioServicesPlaySystemSound(1005) // Fallback
            return
        }
        
        let partials: [(freq: Double, amp: Double, decay: Double)] = [
            (1.0, 1.0, 0.5),
            (1.6, 0.5, 0.7),
            (2.3, 0.3, 0.9),
            (3.1, 0.18, 1.2),
            (4.4, 0.1, 1.5),
            (5.8, 0.05, 2.0)
        ]
        
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let progress = Double(i) / Double(frameCount)
            var sample: Double = 0.0
            
            let attackTime = 0.1
            var attackEnvelope: Double = 1.0
            if time < attackTime {
                let t = time / attackTime
                attackEnvelope = t * t * (3.0 - 2.0 * t)
            }
            
            var fadeOutEnvelope: Double = 1.0
            if progress > 0.4 {
                let fadeProgress = (progress - 0.4) / 0.6
                fadeOutEnvelope = 1.0 - (fadeProgress * fadeProgress)
            }
            
            for partial in partials {
                let freq = fundamentalFreq * partial.freq
                let amp = partial.amp
                let decay = partial.decay
                let decayEnvelope = exp(-decay * time)
                sample += sin(2.0 * .pi * freq * time) * amp * decayEnvelope * attackEnvelope
            }
            channelData[i] = Float(sample) * volume * Float(fadeOutEnvelope)
        }
        
        // Schedule buffer and ensure player node is playing
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            print("🔔 BellPlayer: Buffer playback completed")
        })
        
        // Ensure player node is playing
        if !playerNode.isPlaying {
            playerNode.play()
            print("🔔 BellPlayer: Bell sound playing (engine running: \(audioEngine.isRunning), node playing: \(playerNode.isPlaying))")
        } else {
            print("🔔 BellPlayer: Bell sound scheduled (already playing)")
        }
    }
}


