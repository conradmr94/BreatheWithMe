//
//  NoiseGenerator.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import AVFoundation
import Accelerate

class NoiseGenerator: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private let engine = AVAudioEngine()
    private let sampleRate: Double = 44100.0
    private var isPlaying = false
    private var audioPlayers: [NoiseType: AVAudioPlayer] = [:]
    private var baseVolume: Float = 0.3 // Store the user's desired volume
    private var fadeTimer: Timer?
    private var colorPlayerNodes: [NoiseType: AVAudioPlayerNode] = [:]
    private var colorBuffers: [NoiseType: AVAudioPCMBuffer] = [:]
    
    @Published var isEnabled = false
    @Published var selectedNoiseType: NoiseType = .white
    @Published var selectedNoiseTypes: Set<NoiseType> = [.white]
    @Published var volume: Float = 0.3 // Much lower default volume
    @Published var showInfoMessage = false
    @Published var infoMessage = ""
    @Published private(set) var mixLevels: [NoiseType: Float] = [:]
    
    enum NoiseType: String, CaseIterable {
        case white = "White"
        case pink = "Pink"
        case brown = "Brown"
        case blue = "Blue"
        case green = "Green"
        case rain = "Rain"
        case ocean = "Ocean"
        case wind = "Wind"
        case thunder = "Thunder"
        case forest = "Forest"
        case cafe = "Cafe"
        case city = "City"
        case fire = "Fire"
        case birds = "Birds"
        case night = "Night"
        case nature = "Nature"
        case uplift = "Uplift"
        case fan = "Fan"
        case hz44 = "44hz"
        case hz66 = "66hz"
        case hz10 = "10hz"
        case inspire = "Inspire"
        case misty = "Misty"
        case backdrop = "Backdrop"
        case relax = "Relax"
        case yoga = "Yoga"
        
        var description: String {
            switch self {
            case .white: return "White Noise"
            case .pink: return "Pink Noise"
            case .brown: return "Brown Noise"
            case .blue: return "Blue Noise"
            case .green: return "Green Noise"
            case .rain: return "Rain"
            case .ocean: return "Ocean"
            case .wind: return "Wind"
            case .thunder: return "Thunder"
            case .forest: return "Forest"
            case .cafe: return "Cafe"
            case .city: return "City"
            case .fire: return "Fire"
            case .birds: return "Birds"
            case .night: return "Night"
            case .nature: return "Nature Escape"
            case .uplift: return "Morning Uplift"
            case .fan: return "Fan"
            case .hz44: return "44 Hz"
            case .hz66: return "66 Hz"
            case .hz10: return "10 Hz"
            case .inspire: return "Inspire"
            case .misty: return "Misty"
            case .backdrop: return "Backdrop"
            case .relax: return "Relax"
            case .yoga: return "Yoga"
            }
        }
        
        var icon: String {
            switch self {
            case .white: return "waveform"
            case .pink: return "waveform.circle"
            case .brown: return "waveform.circle.fill"
            case .blue: return "waveform.badge.plus"
            case .green: return "waveform.badge.minus"
            case .rain: return "cloud.rain"
            case .ocean: return "water.waves"
            case .wind: return "wind"
            case .thunder: return "cloud.bolt"
            case .forest: return "tree"
            case .cafe: return "cup.and.saucer"
            case .city: return "building.2"
            case .fire: return "flame"
            case .birds: return "bird"
            case .night: return "moon.stars"
            case .nature: return "leaf.arrow.circlepath"
            case .uplift: return "sun.max"
            case .fan: return "fan"
            case .hz44: return "waveform.path"
            case .hz66: return "waveform.path"
            case .hz10: return "waveform.path"
            case .inspire: return "sparkles"
            case .misty: return "cloud.fog"
            case .backdrop: return "music.note.list"
            case .relax: return "leaf.fill"
            case .yoga: return "figure.yoga"
            }
        }
    }
    
    private func synchronizePlayback() {
        guard isEnabled, isPlaying else { return }
        
        for type in NoiseType.allCases {
            if selectedNoiseTypes.contains(type) {
                if type.isAmbientSound {
                    startAmbientIfNeeded(type)
                } else {
                    startColorNoise(type)
                }
            } else {
                if type.isAmbientSound {
                    stopAmbient(type)
                } else {
                    stopColorNoise(type)
                }
            }
        }
        
        applyVolume(volume)
    }
    
    private func startAmbientIfNeeded(_ type: NoiseType) {
        guard isEnabled else { return }
        
        // Ensure audio player exists - create placeholder if missing
        if audioPlayers[type] == nil {
            print("⚠️ Audio player missing for \(type.rawValue), creating placeholder...")
            createPlaceholderAudio(for: type)
        }
        
        guard let audioPlayer = audioPlayers[type] else {
            print("❌ Failed to create audio player for \(type.rawValue)")
            return
        }
        
        if !audioPlayer.isPlaying {
            audioPlayer.currentTime = 0
            audioPlayer.numberOfLoops = -1
            audioPlayer.play()
            print("✅ Ambient audio started: \(type.rawValue)")
        }
    }
    
    private func stopAmbient(_ type: NoiseType) {
        guard let audioPlayer = audioPlayers[type] else { return }
        if audioPlayer.isPlaying {
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            print("🛑 Ambient audio stopped: \(type.rawValue)")
        }
    }
    
    private func startColorNoise(_ type: NoiseType) {
        guard isEnabled else { return }
        guard let node = colorPlayerNodes[type],
              let buffer = colorBuffers[type] else { return }
        
        if !engine.isRunning {
            do {
                try engine.start()
                print("✅ Audio engine started for color noise")
            } catch {
                print("❌ Failed to start audio engine: \(error)")
                return
            }
        }
        
        if !node.isPlaying {
            node.reset()
            node.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
            node.play()
            print("🎧 Color noise started: \(type.rawValue)")
        }
    }
    
    private func stopColorNoise(_ type: NoiseType) {
        guard let node = colorPlayerNodes[type] else { return }
        if node.isPlaying {
            node.stop()
            node.reset()
            print("🛑 Color noise stopped: \(type.rawValue)")
        }
        
        if colorPlayerNodes.values.allSatisfy({ !$0.isPlaying }) {
            engine.stop()
            print("🛑 Audio engine stopped (no color noise playing)")
        }
    }
    
    override init() {
        super.init()
        mixLevels[selectedNoiseType] = 100.0
        setupAudioSession()
        setupAudioEngine()
        setupAudioFiles()
    }
    
    private func isRealAudioType(_ type: NoiseType) -> Bool {
        return type.isAmbientSound
    }
    
    private func setupAudioSession() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session setup successfully.")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        for noiseType in NoiseType.allCases where !noiseType.isAmbientSound {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mainMixer, format: format)
            node.volume = volume * 0.3
            colorPlayerNodes[noiseType] = node
            colorBuffers[noiseType] = createColorNoiseBuffer(for: noiseType, format: format)
        }
        
        engine.prepare()
    }
    
    private func setupAudioFiles() {
        print("🎵 Setting up real audio files for ambient sounds...")
        
        // Load real audio files for ambient sounds
        for noiseType in NoiseType.allCases {
            if isRealAudioType(noiseType) {
                loadRealAudioFile(for: noiseType)
            }
        }
    }
    
    private func loadRealAudioFile(for type: NoiseType) {
        // Get the filename for the audio type
        let filename = getAudioFilename(for: type)
        
        // Split filename into name and extension
        let components = filename.components(separatedBy: ".")
        guard components.count >= 2 else {
            print("❌ Invalid filename format: \(filename)")
            createPlaceholderAudio(for: type)
            return
        }
        let name = components.dropLast().joined(separator: ".")
        let ext = components.last ?? ""
        
        // Try to load the audio file from the app bundle
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("❌ Could not find audio file: \(filename)")
            // Fallback to placeholder if file not found
            createPlaceholderAudio(for: type)
            return
        }
        
        // Create AVAudioPlayer with the real audio file
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1 // Loop indefinitely
            audioPlayer.volume = 0.5 // Lower volume for ambient sounds
            audioPlayer.delegate = self // Set delegate to handle interruptions
            audioPlayer.prepareToPlay()
            audioPlayers[type] = audioPlayer
            print("✅ Loaded real audio file: \(filename)")
        } catch {
            print("❌ Failed to load audio file \(filename): \(error)")
            // Fallback to placeholder if loading fails
            createPlaceholderAudio(for: type)
        }
    }
    
    private func getAudioFilename(for type: NoiseType) -> String {
            return type.bundleFileName ?? ""
    }
    
    private func createPlaceholderAudio(for type: NoiseType) {
        // Create a simple 10-second audio file for each ambient type
        let duration: Double = 10.0
        let sampleCount = Int(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            print("❌ Failed to create audio format for placeholder: \(type.rawValue)")
            return
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else {
            print("❌ Failed to create audio buffer for placeholder: \(type.rawValue)")
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        guard let channelData = buffer.floatChannelData?[0] else {
            print("❌ Failed to get channel data for placeholder: \(type.rawValue)")
            return
        }
        
        // Generate placeholder ambient sound
        generatePlaceholderAmbient(channelData: channelData, frameCount: sampleCount, type: type)
        
        // Convert buffer to audio data
        let audioData = bufferToData(buffer: buffer)
        
        // Create AVAudioPlayer
        do {
            let audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer.numberOfLoops = -1 // Loop indefinitely
            audioPlayer.volume = 0.5 // Set reasonable volume for placeholder
            audioPlayer.prepareToPlay()
            audioPlayers[type] = audioPlayer
            print("✅ Created placeholder audio for \(type.rawValue)")
        } catch {
            print("❌ Failed to create audio player for \(type): \(error)")
        }
    }
    
    private func generatePlaceholderAmbient(channelData: UnsafeMutablePointer<Float>, frameCount: Int, type: NoiseType) {
        switch type {
        case .rain:
            generateRainPlaceholder(channelData: channelData, frameCount: frameCount)
        case .ocean:
            generateOceanPlaceholder(channelData: channelData, frameCount: frameCount)
        case .wind:
            generateWindPlaceholder(channelData: channelData, frameCount: frameCount)
        case .thunder:
            generateThunderPlaceholder(channelData: channelData, frameCount: frameCount)
        case .forest:
            generateForestPlaceholder(channelData: channelData, frameCount: frameCount)
        case .cafe:
            generateCafePlaceholder(channelData: channelData, frameCount: frameCount)
        case .city:
            generateCityPlaceholder(channelData: channelData, frameCount: frameCount)
        case .fire:
            generateFirePlaceholder(channelData: channelData, frameCount: frameCount)
        case .birds:
            generateBirdsPlaceholder(channelData: channelData, frameCount: frameCount)
        case .night:
            generateNightPlaceholder(channelData: channelData, frameCount: frameCount)
        case .fan:
            generateFanPlaceholder(channelData: channelData, frameCount: frameCount)
        case .hz44:
            generateHz44Placeholder(channelData: channelData, frameCount: frameCount)
        case .hz66:
            generateHz66Placeholder(channelData: channelData, frameCount: frameCount)
        case .hz10:
            generateHz10Placeholder(channelData: channelData, frameCount: frameCount)
        case .inspire:
            generateInspirePlaceholder(channelData: channelData, frameCount: frameCount)
        case .misty:
            generateMistyPlaceholder(channelData: channelData, frameCount: frameCount)
        case .backdrop:
            generateBackdropPlaceholder(channelData: channelData, frameCount: frameCount)
        case .relax:
            generateRelaxPlaceholder(channelData: channelData, frameCount: frameCount)
        case .yoga:
            generateYogaPlaceholder(channelData: channelData, frameCount: frameCount)
        default:
            break
        }
    }
    
    private func bufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        let data = Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
        return data
    }
    
    private func createColorNoiseBuffer(for type: NoiseType, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let duration: Double = 8.0
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        generateNoise(buffer: buffer, type: type)
        return buffer
    }
    
    func startNoise() {
        guard isEnabled else { return }
        guard !selectedNoiseTypes.isEmpty else { return }
        
        print("🎵 Starting ambient sound mix...")
        isPlaying = true
        synchronizePlayback()
        fadeIn(duration: 1.0)
    }
    
    func stopNoise() {
        guard isPlaying else { return }
        
        print("🔇 Stopping ambient sound mix...")
        isPlaying = false
        
        // Cancel any ongoing fade
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        for (type, player) in audioPlayers {
            if player.isPlaying {
                player.stop()
                player.currentTime = 0
                print("✅ Stopped audio for \(type.rawValue)")
            }
        }
        
        for (type, node) in colorPlayerNodes {
            if node.isPlaying {
                node.stop()
                print("✅ Stopped color node for \(type.rawValue)")
            }
        }
        engine.stop()
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume)) // Allow full volume range
        baseVolume = volume // Update base volume when user changes it
        applyVolume(volume)
    }
    
    func fadeIn(duration: TimeInterval = 1.0) {
        // Cancel any existing fade
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        let steps = 50 // Number of volume steps
        let stepDuration = duration / Double(steps)
        var currentStep = 0
        
        // Start from 0 volume
        applyVolume(0.0)
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            let targetVolume = self.baseVolume * progress
            
            self.applyVolume(targetVolume)
            
            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimer = nil
                // Ensure we're at the exact target volume
                self.applyVolume(self.baseVolume)
            }
        }
    }
    
    func fadeOut(duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        // Cancel any existing fade
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        let steps = 50 // Number of volume steps
        let stepDuration = duration / Double(steps)
        var currentStep = 0
        let startVolume = getCurrentVolume()
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                completion?()
                return
            }
            
            currentStep += 1
            let progress = Float(currentStep) / Float(steps)
            let targetVolume = startVolume * (1.0 - progress)
            
            self.applyVolume(targetVolume)
            
            if currentStep >= steps {
                timer.invalidate()
                self.fadeTimer = nil
                // Ensure we're at 0 volume
                self.applyVolume(0.0)
                completion?()
            }
        }
    }
    
    private func applyVolume(_ vol: Float) {
        ensureMixLevelsForCurrentSelection()
        
        for type in selectedNoiseTypes {
            let multiplier = volumeMultiplier(for: type)
            let mixValue = mixLevels[type] ?? 100.0
            let mixFactor = max(0.0, min(1.0, mixValue / 100.0))
            let adjustedVolume = min(1.0, vol * multiplier * mixFactor)
            if let audioPlayer = audioPlayers[type] {
                audioPlayer.volume = adjustedVolume
            }
            if let node = colorPlayerNodes[type] {
                node.volume = adjustedVolume * 0.8
            }
        }
    }
    
    private func getCurrentVolume() -> Float {
        return baseVolume
    }
    
    func showInfoForNoiseType(_ type: NoiseType) {
        switch type {
        case .white:
            infoMessage = "White Noise - Masks distracting sounds like this"
        case .pink:
            infoMessage = "Pink Noise - Promotes deep and uninterrupted focus"
        case .brown:
            infoMessage = "Brown Noise - Produces deep, calming, and soothing sounds that aid relaxation and concentration"
        case .blue:
            infoMessage = "Blue Noise - Boosts alertness, creativity, and productivity"
        case .green:
            infoMessage = "Green Noise - Provides a calm, natural sound that helps with focus and anxiety"
        default:
            return
        }
        
        showInfoMessage = true
        
        // Hide the message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showInfoMessage = false
        }
    }
    
    func toggleNoiseType(_ type: NoiseType) {
        var updatedSelection = selectedNoiseTypes
        
        if updatedSelection.contains(type) {
            updatedSelection.remove(type)
            mixLevels.removeValue(forKey: type)
        } else {
            updatedSelection.insert(type)
        }
        
        selectedNoiseTypes = updatedSelection
        selectedNoiseType = type
        
        if selectedNoiseTypes.isEmpty {
            stopNoise()
        } else {
            rebalanceMixLevels()
            if isEnabled && isPlaying {
                synchronizePlayback()
            }
        }
    }
    
    func setNoiseType(_ type: NoiseType) {
        selectedNoiseTypes = [type]
        selectedNoiseType = type
        mixLevels = [type: 100.0]
        rebalanceMixLevels()
        if isEnabled && isPlaying {
            synchronizePlayback()
        }
    }
    
    var selectedNoiseDescription: String {
        let names = selectedNoiseTypes
            .sorted(by: { $0.description < $1.description })
            .map { $0.description }
        return names.isEmpty ? selectedNoiseType.description : names.joined(separator: ", ")
    }
    
    private func generateNoise(buffer: AVAudioPCMBuffer, type: NoiseType) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        switch type {
        case .rain:
            generateRainNoise(channelData: channelData, frameCount: frameCount)
        case .ocean:
            generateOceanNoise(channelData: channelData, frameCount: frameCount)
        case .wind:
            generateWindNoise(channelData: channelData, frameCount: frameCount)
        case .thunder:
            generateThunderNoise(channelData: channelData, frameCount: frameCount)
        case .forest:
            generateForestNoise(channelData: channelData, frameCount: frameCount)
        case .cafe:
            generateCafeNoise(channelData: channelData, frameCount: frameCount)
        case .city:
            generateCityNoise(channelData: channelData, frameCount: frameCount)
        case .fire:
            generateFireNoise(channelData: channelData, frameCount: frameCount)
        case .birds:
            generateBirdsNoise(channelData: channelData, frameCount: frameCount)
        case .night:
            generateNightNoise(channelData: channelData, frameCount: frameCount)
        case .nature:
            generateNatureNoise(channelData: channelData, frameCount: frameCount)
        case .uplift:
            generateUpliftNoise(channelData: channelData, frameCount: frameCount)
        case .white:
            generateWhiteNoise(channelData: channelData, frameCount: frameCount)
        case .pink:
            generatePinkNoise(channelData: channelData, frameCount: frameCount)
        case .brown:
            generateBrownNoise(channelData: channelData, frameCount: frameCount)
        case .blue:
            generateBlueNoise(channelData: channelData, frameCount: frameCount)
        case .green:
            generateGreenNoise(channelData: channelData, frameCount: frameCount)
        case .fan:
            generateFanPlaceholder(channelData: channelData, frameCount: frameCount)
        case .hz44:
            generateHz44Placeholder(channelData: channelData, frameCount: frameCount)
        case .hz66:
            generateHz66Placeholder(channelData: channelData, frameCount: frameCount)
        case .hz10:
            generateHz10Placeholder(channelData: channelData, frameCount: frameCount)
        case .inspire:
            generateInspirePlaceholder(channelData: channelData, frameCount: frameCount)
        case .misty:
            generateMistyPlaceholder(channelData: channelData, frameCount: frameCount)
        case .backdrop:
            generateBackdropPlaceholder(channelData: channelData, frameCount: frameCount)
        case .relax:
            generateRelaxPlaceholder(channelData: channelData, frameCount: frameCount)
        case .yoga:
            generateYogaPlaceholder(channelData: channelData, frameCount: frameCount)
        }
    }
    
    // MARK: - Simple and Efficient Noise Generation
    
    private func generateRainNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple rain-like noise
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let rain = sin(time * 8.0) * 0.1 + Float.random(in: -0.05...0.05)
            channelData[i] = rain * 0.3
        }
    }
    
    private func generateOceanNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple ocean waves
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let wave = sin(time * 0.5) * 0.2 + sin(time * 1.0) * 0.1
            channelData[i] = wave * 0.4
        }
    }
    
    private func generateWindNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple wind noise
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let wind = sin(time * 0.3) * 0.15 + Float.random(in: -0.03...0.03)
            channelData[i] = wind * 0.3
        }
    }
    
    private func generateThunderNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple thunder rumble
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let rumble = sin(time * 0.1) * 0.1 + Float.random(in: -0.01...0.01)
            channelData[i] = rumble * 0.2
        }
    }
    
    private func generateForestNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple forest ambient
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let forest = sin(time * 0.4) * 0.1 + sin(time * 2.0) * 0.03
            channelData[i] = forest * 0.3
        }
    }
    
    private func generateCafeNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple cafe ambiance
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let cafe = sin(time * 3.0) * 0.05 + Float.random(in: -0.02...0.02)
            channelData[i] = cafe * 0.2
        }
    }
    
    private func generateCityNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // City ambiance: traffic and urban sounds with varied frequencies
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let traffic = sin(time * 1.5) * 0.08 + sin(time * 5.0) * 0.04
            let urban = Float.random(in: -0.03...0.03)
            channelData[i] = (traffic + urban) * 0.25
        }
    }
    
    private func generateFireNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Fire crackling: noise bursts with low rumble
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let crackle = Float.random(in: -0.15...0.15) * abs(sin(time * 6.0))
            let rumble = sin(time * 1.5) * 0.05
            channelData[i] = (crackle + rumble) * 0.3
        }
    }
    
    private func generateBirdsNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Bird chirping: high frequency modulated sounds
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let chirp1 = sin(time * 8.0) * abs(sin(time * 0.3)) * 0.08
            let chirp2 = sin(time * 12.0) * abs(sin(time * 0.5)) * 0.06
            channelData[i] = (chirp1 + chirp2) * 0.3
        }
    }
    
    private func generateNightNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let lowHum = sin(time * 0.2) * 0.18
            let gentleBreeze = sin(time * 0.9) * 0.07
            let insect = sin(time * 5.5) * abs(sin(time * 0.4)) * 0.06
            let distantOwl = sin(time * 2.3) * abs(sin(time * 0.15)) * 0.04
            let random = Float.random(in: -0.025...0.025)
            channelData[i] = (lowHum + gentleBreeze + insect + distantOwl + random) * 0.35
        }
    }
    
    private func generateNatureNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Blend of forest ambience with gentle brook
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let brook = sin(time * 1.2) * 0.08 + sin(time * 0.65) * 0.05
            let canopy = sin(time * 0.25) * 0.12
            let birds = sin(time * 6.0) * abs(sin(time * 0.35)) * 0.04
            channelData[i] = (brook + canopy + birds + Float.random(in: -0.02...0.02)) * 0.35
        }
    }
    
    private func generateUpliftNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Soft harmonic pads for uplifting wake-up tone
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let base = sin(time * 1.8) * 0.12
            let harmony = sin(time * 2.4) * 0.09
            let shimmer = sin(time * 7.0) * 0.04
            channelData[i] = (base + harmony + shimmer) * 0.35
        }
    }
    
    private func generateWhiteNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple white noise - reduced volume for color noise
        for i in 0..<frameCount {
            channelData[i] = Float.random(in: -0.1...0.1) * 0.1 // Much lower volume
        }
    }
    
    private func generatePinkNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple pink noise - reduced volume for color noise
        var lastValue: Float = 0.0
        for i in 0..<frameCount {
            let white = Float.random(in: -1.0...1.0)
            lastValue = (lastValue + white * 0.1) * 0.9
            channelData[i] = lastValue * 0.1 // Much lower volume
        }
    }
    
    private func generateBrownNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Simple brown noise
        var lastValue: Float = 0.0
        for i in 0..<frameCount {
            let white = Float.random(in: -1.0...1.0)
            lastValue = (lastValue + white * 0.02) * 0.99
            channelData[i] = lastValue * 0.1 // Much lower volume for color noise
        }
    }
    
    // MARK: - Placeholder Ambient Sound Generation (for real audio files)
    
    private func generateRainPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder rain sound - in real implementation, load actual rain audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let rain = sin(time * 8.0) * 0.1 + Float.random(in: -0.05...0.05)
            channelData[i] = rain * 0.2
        }
    }
    
    private func generateOceanPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder ocean sound - in real implementation, load actual ocean audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let wave = sin(time * 0.5) * 0.2 + sin(time * 1.0) * 0.1
            channelData[i] = wave * 0.2
        }
    }
    
    private func generateWindPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder wind sound - in real implementation, load actual wind audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let wind = sin(time * 0.3) * 0.15 + Float.random(in: -0.03...0.03)
            channelData[i] = wind * 0.2
        }
    }
    
    private func generateThunderPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder thunder sound - in real implementation, load actual thunder audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let rumble = sin(time * 0.1) * 0.1 + Float.random(in: -0.01...0.01)
            channelData[i] = rumble * 0.2
        }
    }
    
    private func generateForestPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder forest sound - in real implementation, load actual forest audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let forest = sin(time * 0.4) * 0.1 + sin(time * 2.0) * 0.03
            channelData[i] = forest * 0.2
        }
    }
    
    private func generateCafePlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder cafe sound - in real implementation, load actual cafe audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let cafe = sin(time * 3.0) * 0.05 + Float.random(in: -0.02...0.02)
            channelData[i] = cafe * 0.2
        }
    }
    
    private func generateCityPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder city sound - in real implementation, load actual city audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let traffic = sin(time * 1.5) * 0.08 + sin(time * 5.0) * 0.04
            let urban = Float.random(in: -0.03...0.03)
            channelData[i] = (traffic + urban) * 0.2
        }
    }
    
    private func generateFirePlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder fire sound - in real implementation, load actual fire audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let crackle = Float.random(in: -0.15...0.15) * abs(sin(time * 6.0))
            let rumble = sin(time * 1.5) * 0.05
            channelData[i] = (crackle + rumble) * 0.2
        }
    }
    
    private func generateBirdsPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder birds sound - in real implementation, load actual birds audio
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let chirp1 = sin(time * 8.0) * abs(sin(time * 0.3)) * 0.08
            let chirp2 = sin(time * 12.0) * abs(sin(time * 0.5)) * 0.06
            channelData[i] = (chirp1 + chirp2) * 0.2
        }
    }
    
    private func generateNightPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let lowHum = sin(time * 0.25) * 0.12
            let distantWind = sin(time * 0.8) * 0.05
            let insect = sin(time * 6.0) * abs(sin(time * 0.35)) * 0.04
            let random = Float.random(in: -0.02...0.02)
            channelData[i] = (lowHum + distantWind + insect + random) * 0.25
        }
    }
    
    private func generateFanPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder fan sound - steady white noise with low frequency rumble
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let steady = Float.random(in: -0.08...0.08)
            let rumble = sin(time * 1.2) * 0.05
            let whir = sin(time * 4.0) * 0.03
            channelData[i] = (steady + rumble + whir) * 0.25
        }
    }
    
    private func generateHz44Placeholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder 44 Hz tone - pure sine wave at 44 Hz
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            channelData[i] = sin(time * 44.0 * 2.0 * .pi) * 0.2
        }
    }
    
    private func generateHz66Placeholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder 66 Hz tone - pure sine wave at 66 Hz
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            channelData[i] = sin(time * 66.0 * 2.0 * .pi) * 0.2
        }
    }
    
    private func generateHz10Placeholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder 10 Hz tone - pure sine wave at 10 Hz
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            channelData[i] = sin(time * 10.0 * 2.0 * .pi) * 0.2
        }
    }
    
    private func generateInspirePlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder inspire sound - uplifting harmonic pads
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let base = sin(time * 2.0) * 0.1
            let harmony = sin(time * 3.0) * 0.08
            let shimmer = sin(time * 8.0) * 0.04
            channelData[i] = (base + harmony + shimmer) * 0.3
        }
    }
    
    private func generateMistyPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder misty sound - soft, ethereal ambient
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let low = sin(time * 0.3) * 0.1
            let mid = sin(time * 1.5) * 0.06
            let high = sin(time * 5.0) * 0.03
            channelData[i] = (low + mid + high) * 0.3
        }
    }
    
    private func generateBackdropPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder backdrop sound - subtle ambient texture
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let texture = Float.random(in: -0.02...0.02)
            let gentle = sin(time * 0.5) * 0.08
            channelData[i] = (texture + gentle) * 0.25
        }
    }
    
    private func generateRelaxPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder relax sound - calming, peaceful tones
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let calm = sin(time * 0.4) * 0.12
            let peace = sin(time * 1.2) * 0.07
            let gentle = sin(time * 3.0) * 0.04
            channelData[i] = (calm + peace + gentle) * 0.3
        }
    }
    
    private func generateYogaPlaceholder(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Placeholder yoga sound - meditative, flowing tones
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let flow = sin(time * 0.6) * 0.1
            let meditate = sin(time * 2.0) * 0.07
            let breath = sin(time * 4.5) * 0.04
            channelData[i] = (flow + meditate + breath) * 0.3
        }
    }
    
    deinit {
        stopNoise()
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard isPlaying else { return }
        if let (type, storedPlayer) = audioPlayers.first(where: { $0.value === player }) {
            print("🔄 Audio finished for \(type.rawValue), restarting...")
            storedPlayer.play()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
    }
    
    // MARK: - New Color Noise Generation
    
    private func generateBlueNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Blue noise has more high-frequency content, good for alertness
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let highFreq = sin(time * 8000.0) * 0.1
            let midFreq = sin(time * 4000.0) * 0.05
            let random = Float.random(in: -0.1...0.1)
            channelData[i] = (highFreq + midFreq + random) * 0.1
        }
    }
    
    private func generateGreenNoise(channelData: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Green noise is between pink and white, natural and calming
        for i in 0..<frameCount {
            let time = Float(i) / Float(sampleRate)
            let natural = sin(time * 2000.0) * 0.08 + sin(time * 1000.0) * 0.04
            let random = Float.random(in: -0.05...0.05)
            channelData[i] = (natural + random) * 0.1
        }
    }
}

extension NoiseGenerator {
    func mixWeight(for type: NoiseType) -> Float {
        ensureMixLevelsForCurrentSelection()
        let fallback = selectedNoiseTypes.isEmpty ? 0.0 : (100.0 / Float(selectedNoiseTypes.count))
        return max(0.0, min(100.0, mixLevels[type] ?? fallback))
    }
    
    func mixShare(for type: NoiseType) -> Float {
        ensureMixLevelsForCurrentSelection()
        let total = selectedNoiseTypes.reduce(0) { $0 + max(0.0, mixLevels[$1] ?? 0) }
        guard total > 0 else {
            return selectedNoiseTypes.count <= 1 ? 1.0 : 0.0
        }
        return max(0.0, (mixLevels[type] ?? 0) / total)
    }
    
    func setMixWeight(_ value: Float, for type: NoiseType) {
        guard selectedNoiseTypes.contains(type) else { return }
        ensureMixLevelsForCurrentSelection()
        
        let clamped = max(0.0, min(100.0, value))
        mixLevels[type] = clamped
        redistributeMix(afterAdjusting: type)
        normalizeMixLevelsToHundred()
        
        if isEnabled && isPlaying {
            applyVolume(volume)
        }
    }
    
    func equalizeMix() {
        guard !selectedNoiseTypes.isEmpty else { return }
        rebalanceMixLevels()
        if isEnabled && isPlaying {
            applyVolume(volume)
        }
    }
    
    func applyMix(weights: [NoiseType: Float]) {
        guard !weights.isEmpty else { return }
        ensureMixLevelsForCurrentSelection()
        
        let ordered = orderedSelectedTypes()
        var sanitized: [NoiseType: Float] = [:]
        
        for type in ordered {
            if let rawValue = weights[type], !rawValue.isNaN {
                let clamped = max(0.0, min(100.0, rawValue))
                sanitized[type] = clamped
            } else if let existing = mixLevels[type] {
                sanitized[type] = existing
            }
        }
        
        guard !sanitized.isEmpty else { return }
        mixLevels = sanitized
        normalizeMixLevelsToHundred()
        
        if isEnabled && isPlaying {
            applyVolume(volume)
        }
    }
}

private extension NoiseGenerator {
    func orderedSelectedTypes() -> [NoiseType] {
        selectedNoiseTypes.sorted { $0.description < $1.description }
    }
    
    func ensureMixLevelsForCurrentSelection() {
        guard !selectedNoiseTypes.isEmpty else {
            mixLevels.removeAll()
            return
        }
        
        let count = selectedNoiseTypes.count
        let fallback = 100.0 / Float(count)
        
        for type in selectedNoiseTypes {
            if mixLevels[type] == nil {
                mixLevels[type] = fallback
            }
        }
        
        let staleKeys = mixLevels.keys.filter { !selectedNoiseTypes.contains($0) }
        for key in staleKeys {
            mixLevels.removeValue(forKey: key)
        }
        
        normalizeMixLevelsToHundred()
    }
    
    func rebalanceMixLevels() {
        guard !selectedNoiseTypes.isEmpty else {
            mixLevels.removeAll()
            return
        }
        
        let staleKeys = mixLevels.keys.filter { !selectedNoiseTypes.contains($0) }
        for key in staleKeys {
            mixLevels.removeValue(forKey: key)
        }
        
        let ordered = orderedSelectedTypes()
        let count = ordered.count
        if count == 1, let only = ordered.first {
            mixLevels[only] = 100.0
            return
        }
        
        let equalValue = 100.0 / Float(count)
        var remaining: Float = 100.0
        
        for (index, type) in ordered.enumerated() {
            if index == count - 1 {
                mixLevels[type] = max(0.0, remaining)
            } else {
                mixLevels[type] = equalValue
                remaining -= equalValue
            }
        }
    }
    
    func normalizeMixLevelsToHundred() {
        guard !selectedNoiseTypes.isEmpty else { return }
        let total = selectedNoiseTypes.reduce(0) { $0 + max(0.0, mixLevels[$1] ?? 0) }
        
        if abs(total - 100.0) < 0.01 {
            return
        }
        
        guard total > 0 else {
            rebalanceMixLevels()
            return
        }
        
        let scale = 100.0 / total
        var remaining: Float = 100.0
        let ordered = orderedSelectedTypes()
        
        for (index, type) in ordered.enumerated() {
            if index == ordered.count - 1 {
                mixLevels[type] = max(0.0, remaining)
            } else {
                let newValue = max(0.0, (mixLevels[type] ?? 0) * scale)
                mixLevels[type] = newValue
                remaining -= newValue
            }
        }
    }
    
    func redistributeMix(afterAdjusting adjustedType: NoiseType) {
        let others = orderedSelectedTypes().filter { $0 != adjustedType }
        guard let adjustedValue = mixLevels[adjustedType] else { return }
        
        if others.isEmpty {
            mixLevels[adjustedType] = 100.0
            return
        }
        
        let available = max(0.0, 100.0 - adjustedValue)
        let currentTotal = others.reduce(0) { $0 + max(0.0, mixLevels[$1] ?? 0) }
        
        if currentTotal <= 0 {
            distributeEvenShare(available: available, to: others)
            return
        }
        
        var remaining = available
        for (index, type) in others.enumerated() {
            if index == others.count - 1 {
                mixLevels[type] = max(0.0, remaining)
            } else {
                let weight = max(0.0, mixLevels[type] ?? 0)
                let newValue = available * (weight / currentTotal)
                mixLevels[type] = newValue
                remaining -= newValue
            }
        }
    }
    
    func distributeEvenShare(available: Float, to types: [NoiseType]) {
        guard !types.isEmpty else { return }
        let equalShare = available / Float(types.count)
        var remaining = available
        
        for (index, type) in types.enumerated() {
            if index == types.count - 1 {
                mixLevels[type] = max(0.0, remaining)
            } else {
                mixLevels[type] = equalShare
                remaining -= equalShare
            }
        }
    }
    
    func volumeMultiplier(for type: NoiseType) -> Float {
        switch type {
        case .birds:
            return 9.0
        case .forest:
            return 4.0
        case .night:
            return 16.0
        case .nature:
            return 2.5
        case .uplift:
            return 1.8
        case .thunder:
            return 0.25
        case .rain:
            return 0.4
        case .ocean:
            return 0.35
        default:
            return 1.0
        }
    }
}

// MARK: - Alarm Support Helpers

extension NoiseGenerator.NoiseType {
    /// Nature/ambient sounds that have backing audio assets and are eligible for alarms.
    static var alarmEligibleCases: [NoiseGenerator.NoiseType] {
        [.rain, .ocean, .wind, .thunder, .forest, .cafe, .city, .fire, .birds, .night, .nature, .uplift, .fan, .hz44, .hz66, .hz10, .inspire, .misty, .backdrop, .relax, .yoga]
    }

    /// Indicates whether this noise type maps to a bundled ambient sound asset.
    var isAmbientSound: Bool {
        Self.alarmEligibleCases.contains(self)
    }

    /// Filename (including extension) for the bundled audio asset, if available.
    var bundleFileName: String? {
        switch self {
        case .rain: return "rain.mp3"
        case .ocean: return "ocean.mp3"
        case .wind: return "wind.mp3"
        case .thunder: return "thunder.mp3"
        case .forest: return "forest.mp3"
        case .cafe: return "cafe.mp3"
        case .city: return "city.mp3"
        case .fire: return "fire.mp3"
        case .birds: return "birds.mp3"
        case .night: return "night.mp3"
        case .nature: return "nature.mp3"
        case .uplift: return "uplift.mp3"
        case .fan: return "fan.mp3"
        case .hz44: return "44hz.mp3"
        case .hz66: return "66hz.mp3"
        case .hz10: return "10hz.mp3"
        case .inspire: return "inspire.m4a"
        case .misty: return "misty.mp3"
        case .backdrop: return "backdrop.mp3"
        case .relax: return "relax.mp3"
        case .yoga: return "yoga.mp3"
        default: return nil
        }
    }
}
