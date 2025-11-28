//
//  NoiseOptionsModal.swift
//  BreatheWithMe
//
//  Shared modal for sound selection across Walk, Focus, and Sleep views
//

import SwiftUI

// MARK: - Sound Category Model
struct SoundCategory {
    let name: String
    let icon: String
    let sounds: [NoiseGenerator.NoiseType]
    
    static let allCategories: [SoundCategory] = [
        SoundCategory(name: "Nature", icon: "leaf", sounds: [.rain, .ocean, .wind, .thunder, .forest, .birds, .night, .cafe, .city, .fire, .nature, .fan]),
        SoundCategory(name: "Noise", icon: "waveform", sounds: [.white, .pink, .brown, .blue, .green]),
        SoundCategory(name: "Frequency", icon: "slider.horizontal.3", sounds: [.hz44, .hz66, .hz10]),
        SoundCategory(name: "Melody", icon: "music.note", sounds: [.uplift, .inspire, .misty, .backdrop, .relax, .yoga])
    ]
}

// MARK: - Noise Options Modal
struct NoiseOptionsModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var noiseGenerator: NoiseGenerator
    let accentColor: Color
    let isRunning: Bool
    let title: String
    @State private var showMixerSheet = false
    
    var body: some View {
        let modalWidth: CGFloat = 400
        let modalHeight: CGFloat = 680
        let toggleBinding = Binding(
            get: { noiseGenerator.isEnabled },
            set: { newValue in
                noiseGenerator.isEnabled = newValue
                if newValue {
                    if isRunning { noiseGenerator.startNoise() }
                } else {
                    noiseGenerator.stopNoise()
                }
            }
        )
        
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Toggle(isOn: toggleBinding) {
                    EmptyView()
                }
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                .accessibilityLabel("\(title) toggle")
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SoundCategory.allCategories, id: \.name) { category in
                        CategorySection(
                            category: category,
                            selectedNoiseTypes: noiseGenerator.selectedNoiseTypes,
                            accentColor: accentColor,
                            onSoundSelected: { noiseType in
                                // Check if sound is currently selected (before toggle)
                                let wasSelected = noiseGenerator.selectedNoiseTypes.contains(noiseType)
                                
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    noiseGenerator.toggleNoiseType(noiseType)
                                    // Auto-enable sounds when a sound is selected
                                    if !noiseGenerator.selectedNoiseTypes.isEmpty && !noiseGenerator.isEnabled {
                                        noiseGenerator.isEnabled = true
                                        if isRunning {
                                            noiseGenerator.startNoise()
                                        }
                                    }
                                }
                                
                                // Only show info message when selecting (not deselecting)
                                let isNowSelected = noiseGenerator.selectedNoiseTypes.contains(noiseType)
                                if !wasSelected && isNowSelected && [.white, .pink, .brown, .blue, .green, .hz44, .hz66, .hz10].contains(noiseType) {
                                    noiseGenerator.showInfoForNoiseType(noiseType)
                                }
                            }
                        )
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMixerSheet = true
                }
            }) {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accentColor, lineWidth: 1.2)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                    )
                    .overlay(
                        Text("Mix")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(accentColor)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .frame(width: modalWidth, height: modalHeight)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 24, x: 0, y: 12)
        )
        .overlay(
            // Info message overlay for noise type descriptions
            Group {
                if noiseGenerator.showInfoMessage {
                    VStack {
                        Spacer()
                        Text(noiseGenerator.infoMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.8))
                            )
                            .padding(.horizontal, 40)
                            .padding(.bottom, 80)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        )
        .sheet(isPresented: $showMixerSheet) {
            SoundMixerSheetView(
                noiseGenerator: noiseGenerator,
                accentColor: accentColor
            )
        }
    }
}

// MARK: - Category Section Component
struct CategorySection: View {
    let category: SoundCategory
    let selectedNoiseTypes: Set<NoiseGenerator.NoiseType>
    let accentColor: Color
    let onSoundSelected: (NoiseGenerator.NoiseType) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                Text(category.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(category.sounds, id: \.self) { noiseType in
                        SoundTileView(
                            noiseType: noiseType,
                            isSelected: selectedNoiseTypes.contains(noiseType),
                            accentColor: accentColor,
                            onTap: {
                                onSoundSelected(noiseType)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Sound Mixer Sheet
struct SoundMixerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var noiseGenerator: NoiseGenerator
    let accentColor: Color
    
    private var activeSounds: [NoiseGenerator.NoiseType] {
        noiseGenerator.selectedNoiseTypes
            .sorted { $0.description < $1.description }
    }
    
    private var hasMixableSounds: Bool {
        activeSounds.count > 1
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                ScrollView {
                    VStack(spacing: 18) {
                        if activeSounds.isEmpty {
                            MixEmptyStateView(
                                title: "No active sounds",
                                message: "Choose at least one sound from the sound sheet to begin mixing.",
                                accentColor: accentColor
                            )
                        } else if !hasMixableSounds {
                            MixEmptyStateView(
                                title: "Add one more layer",
                                message: "Turn on another sound to unlock the circular mixer and start shaping the blend.",
                                accentColor: accentColor
                            )
                        } else {
                            CircularMixControl(
                                noiseGenerator: noiseGenerator,
                                sounds: activeSounds,
                                accentColor: accentColor
                            )
                            .frame(height: 360)
                            .padding(.horizontal, 6)
                            
                            Text("Drag the glowing dot closer to a sound icon to boost it. Moving toward the center evens everything out.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(red: 0.4, green: 0.45, blue: 0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                            
                            MixShareGrid(
                                noiseGenerator: noiseGenerator,
                                sounds: activeSounds,
                                accentColor: accentColor
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                }
                
                if hasMixableSounds {
                    Button(action: {
                        noiseGenerator.equalizeMix()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Balance Mix")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(accentColor.opacity(0.6), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(accentColor)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(24)
            .navigationTitle("Sound Mixer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(accentColor)
                }
            }
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view.presentationDetents([.medium, .large])
            } else {
                view
            }
        }
    }
}

// MARK: - Mix Empty State View
private struct MixEmptyStateView: View {
    let title: String
    let message: String
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "circle.dotted")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(accentColor)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
            Text(message)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.35, green: 0.4, blue: 0.5))
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 8)
        )
    }
}

// MARK: - Circular Mix Control
private struct CircularMixControl: View {
    @ObservedObject var noiseGenerator: NoiseGenerator
    let sounds: [NoiseGenerator.NoiseType]
    let accentColor: Color
    
    @State private var normalizedPosition: CGPoint = .zero
    @State private var isDragging = false
    
    private var mixSignature: [Float] {
        sounds.map { noiseGenerator.mixShare(for: $0) }
    }
    
    var body: some View {
        GeometryReader { geo in
            let minSide = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let dialRadius = max((minSide / 2) - 12, 90)
            let controlRadius = max(dialRadius - 48, dialRadius * 0.65)
            let normalizedPoints = perimeterPositions()
            let dotPosition = CGPoint(
                x: center.x + normalizedPosition.x * controlRadius,
                y: center.y + normalizedPosition.y * controlRadius
            )
            
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.35),
                                accentColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: dialRadius * 2, height: dialRadius * 2)
                    .overlay(
                        Circle()
                            .fill(accentColor.opacity(0.05))
                            .frame(width: dialRadius * 2, height: dialRadius * 2)
                    )
                
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 8]))
                    .foregroundColor(accentColor.opacity(0.25))
                    .frame(width: controlRadius * 2, height: controlRadius * 2)
                
                ForEach(Array(sounds.enumerated()), id: \.element) { index, sound in
                    if index < normalizedPoints.count {
                        let basePoint = normalizedPoints[index]
                        let iconPosition = CGPoint(
                            x: center.x + basePoint.x * dialRadius,
                            y: center.y + basePoint.y * dialRadius
                        )
                        
                        Path { path in
                            path.move(to: iconPosition)
                            path.addLine(to: dotPosition)
                        }
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 46, height: 46)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .overlay(
                                Image(systemName: sound.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(accentColor)
                            )
                            .position(iconPosition)
                    }
                }
                
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.45)
                            ]),
                            center: .center,
                            startRadius: 2,
                            endRadius: 36
                        )
                    )
                    .frame(width: 34, height: 34)
                    .shadow(color: accentColor.opacity(0.35), radius: 18, x: 0, y: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
                            .frame(width: 34, height: 34)
                    )
                    .position(dotPosition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let vector = CGPoint(
                            x: value.location.x - center.x,
                            y: value.location.y - center.y
                        )
                        let normalized = normalize(vector: vector, maxRadius: controlRadius)
                        normalizedPosition = normalized
                        updateMixWeights(using: normalized)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
        .onAppear {
            normalizedPosition = normalizedPointFromMix()
        }
        .onChange(of: sounds) { _ in
            normalizedPosition = normalizedPointFromMix()
        }
        .onChange(of: mixSignature) { _ in
            guard !isDragging else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                normalizedPosition = normalizedPointFromMix()
            }
        }
    }
    
    private func perimeterPositions() -> [CGPoint] {
        guard !sounds.isEmpty else { return [] }
        let count = sounds.count
        return (0..<count).map { index in
            let angle = (Double(index) / Double(count)) * (.pi * 2) - .pi / 2
            return CGPoint(x: cos(angle), y: sin(angle))
        }
    }
    
    private func normalizedPointFromMix() -> CGPoint {
        guard !sounds.isEmpty else { return .zero }
        let positions = perimeterPositions()
        var result = CGPoint.zero
        
        for (index, share) in mixSignature.enumerated() where index < positions.count {
            let fraction = CGFloat(share)
            result.x += positions[index].x * fraction
            result.y += positions[index].y * fraction
        }
        return result
    }
    
    private func normalize(vector: CGPoint, maxRadius: CGFloat) -> CGPoint {
        guard maxRadius > 0 else { return .zero }
        var normalized = CGPoint(x: vector.x / maxRadius, y: vector.y / maxRadius)
        let length = normalized.magnitude
        if length > 1 {
            normalized.x /= length
            normalized.y /= length
        }
        return normalized
    }
    
    private func updateMixWeights(using normalized: CGPoint) {
        let positions = perimeterPositions()
        guard !positions.isEmpty else { return }
        
        var rawWeights: [NoiseGenerator.NoiseType: CGFloat] = [:]
        var total: CGFloat = 0
        let softness: CGFloat = 0.15
        
        for (index, sound) in sounds.enumerated() where index < positions.count {
            let distance = normalized.distance(to: positions[index])
            let weight = 1 / ((distance + softness) * (distance + softness))
            rawWeights[sound] = weight
            total += weight
        }
        
        guard total > 0 else { return }
        var scaled: [NoiseGenerator.NoiseType: Float] = [:]
        
        for sound in sounds {
            if let weight = rawWeights[sound] {
                let fraction = weight / total
                scaled[sound] = Float(fraction * 100)
            }
        }
        
        noiseGenerator.applyMix(weights: scaled)
    }
}

// MARK: - Mix Share Grid
private struct MixShareGrid: View {
    @ObservedObject var noiseGenerator: NoiseGenerator
    let sounds: [NoiseGenerator.NoiseType]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mix Breakdown")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(red: 0.25, green: 0.3, blue: 0.4))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(sounds, id: \.self) { sound in
                    MixShareCard(
                        noiseType: sound,
                        share: noiseGenerator.mixShare(for: sound),
                        accentColor: accentColor
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Mix Share Card
private struct MixShareCard: View {
    let noiseType: NoiseGenerator.NoiseType
    let share: Float
    let accentColor: Color
    
    private var shareText: String {
        "\(Int(round(share * 100)))%"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: noiseType.icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.12))
                    )
                Text(noiseType.description)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                Spacer()
                Text(shareText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.6))
            }
            
            ProgressView(value: Double(share), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: accentColor))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - CGPoint Extension
private extension CGPoint {
    var magnitude: CGFloat {
        sqrt(x * x + y * y)
    }
    
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

