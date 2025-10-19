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
    private let player = AVAudioPlayerNode()
    private var currentNoiseType: NoiseType = .white
    private let sampleRate: Double = 44100.0
    private var isPlaying = false
    private var audioPlayers: [NoiseType: AVAudioPlayer] = [:]
    
    @Published var isEnabled = false
    @Published var selectedNoiseType: NoiseType = .white
    @Published var volume: Float = 0.3 // Much lower default volume
    @Published var showInfoMessage = false
    @Published var infoMessage = ""
    
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
            }
        }
    }
    
    override init() {
        super.init()
        setupAudioSession()
        setupAudioEngine()
        setupAudioFiles()
    }
    
    private func isRealAudioType(_ type: NoiseType) -> Bool {
        switch type {
        case .rain, .ocean, .wind, .thunder, .forest, .cafe, .city, .fire, .birds:
            return true
        case .white, .pink, .brown, .blue, .green:
            return false
        }
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
        // Attach player to engine
        engine.attach(player)
        
        // Connect player to main mixer with proper format
        let mainMixer = engine.mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: mainMixer, format: format)
        
        // Set volume
        player.volume = volume
        
        // Prepare the engine
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
        
        // Try to load the audio file from the app bundle
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
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
        switch type {
        case .rain: return "rain.mp3"
        case .ocean: return "ocean.mp3"
        case .wind: return "wind.mp3"
        case .thunder: return "thunder.mp3"
        case .forest: return "forest.mp3"
        case .cafe: return "cafe.mp3"
        case .city: return "city.mp3"
        case .fire: return "fire.mp3"
        case .birds: return "birds.mp3"
        default: return ""
        }
    }
    
    private func createPlaceholderAudio(for type: NoiseType) {
        // Create a simple 10-second audio file for each ambient type
        let duration: Double = 10.0
        let sampleCount = Int(duration * sampleRate)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else { return }
        
        buffer.frameLength = AVAudioFrameCount(sampleCount)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Generate placeholder ambient sound
        generatePlaceholderAmbient(channelData: channelData, frameCount: sampleCount, type: type)
        
        // Convert buffer to audio data
        let audioData = bufferToData(buffer: buffer)
        
        // Create AVAudioPlayer
        do {
            let audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer.numberOfLoops = -1 // Loop indefinitely
            audioPlayer.volume = 0.2 // Lower volume for ambient sounds
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
        default:
            break
        }
    }
    
    private func bufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        let data = Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
        return data
    }
    
    func startNoise() {
        guard !isPlaying else { return }
        
        print("🎵 Starting ambient sound...")
        currentNoiseType = selectedNoiseType
        isPlaying = true
        isEnabled = true
        
        if isRealAudioType(currentNoiseType) {
            // Use real audio file
            if let audioPlayer = audioPlayers[currentNoiseType] {
                audioPlayer.volume = volume
                audioPlayer.numberOfLoops = -1 // Ensure infinite looping
                audioPlayer.play()
                print("✅ Real audio started: \(currentNoiseType.rawValue) (looping: \(audioPlayer.numberOfLoops))")
            } else {
                print("❌ No audio player found for \(currentNoiseType.rawValue)")
            }
        } else {
            // Use generated noise
            do {
                try engine.start()
                print("✅ Audio engine started successfully")
            } catch {
                print("❌ Failed to start audio engine: \(error)")
                return
            }
            
            generateAndPlayNoise()
            print("🎧 Generated noise started for type: \(currentNoiseType.rawValue)")
        }
    }
    
    func stopNoise() {
        guard isPlaying else { return }
        
        print("🔇 Stopping ambient sound...")
        isPlaying = false
        isEnabled = false
        
        if isRealAudioType(currentNoiseType) {
            // Stop real audio file
            if let audioPlayer = audioPlayers[currentNoiseType] {
                audioPlayer.stop()
            }
            print("✅ Real audio stopped")
        } else {
            // Stop generated noise
            player.stop()
            engine.stop()
            print("✅ Generated noise stopped")
        }
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume)) // Allow full volume range
        
        if isRealAudioType(currentNoiseType) {
            // Set volume for real audio files
            if let audioPlayer = audioPlayers[currentNoiseType] {
                audioPlayer.volume = volume
            }
        } else {
            // Set volume for generated noise (reduced for color noise)
            let reducedVolume = volume * 0.3 // Much lower volume for color noise
            player.volume = reducedVolume
        }
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
    
    func setNoiseType(_ type: NoiseType) {
        selectedNoiseType = type
        if isPlaying {
            // Restart with new noise type
            stopNoise()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startNoise()
            }
        }
    }
    
    private func generateAndPlayNoise() {
        let bufferSize: AVAudioFrameCount = 2048 // Larger buffer for better performance
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        
        // Create a repeating buffer
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize) else {
            print("Failed to create audio buffer")
            return
        }
        buffer.frameLength = bufferSize
        
        // Generate noise based on type
        generateNoise(buffer: buffer, type: currentNoiseType)
        
        // Schedule the buffer to play repeatedly
        player.scheduleBuffer(buffer, at: nil, options: .loops) { [weak self] in
            // This completion handler is called when the buffer finishes playing
            // Since we're looping, this won't be called until we stop
            DispatchQueue.main.async {
                if let self = self, self.isPlaying {
                    // Regenerate buffer to avoid memory issues
                    self.generateAndPlayNoise()
                }
            }
        }
        
        player.play()
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
    
    deinit {
        stopNoise()
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // This should not be called since numberOfLoops = -1, but just in case
        if isPlaying && isRealAudioType(currentNoiseType) {
            print("🔄 Audio finished, restarting...")
            player.play()
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