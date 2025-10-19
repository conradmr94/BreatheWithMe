//
//  BellPlayer.swift
//  BreatheWithMe
//

import Foundation
import AVFoundation

final class BellPlayer {
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    init() {
        setupAudio()
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ BellPlayer: Failed to setup audio session: \(error)")
        }
        
        audioEngine.attach(playerNode)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("❌ BellPlayer: Failed to start audio engine: \(error)")
        }
    }
    
    func playBell() {
        let sampleRate: Double = 44100.0
        let duration: Double = 3.5
        let fundamentalFreq: Double = 180.0
        let volume: Float = 0.08
        
        let frameCount = Int(duration * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else { return }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
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
            channelData[i] = Float(sample) * volume * Float(fadeOutEnvelope) * 0.15
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}


