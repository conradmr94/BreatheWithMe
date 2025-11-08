//
//  SoundTileView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

/// Shared tile used to present noise options inside the sound modals.
struct SoundTileView: View {
    let noiseType: NoiseGenerator.NoiseType
    let isSelected: Bool
    let accentColor: Color
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void
    
    init(
        noiseType: NoiseGenerator.NoiseType,
        isSelected: Bool,
        accentColor: Color,
        width: CGFloat = 120,
        height: CGFloat = 140,
        onTap: @escaping () -> Void
    ) {
        self.noiseType = noiseType
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.width = width
        self.height = height
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: noiseType.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : accentColor)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(isSelected ? accentColor.opacity(0.35) : accentColor.opacity(0.15))
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                            )
                    )
                
                Text(noiseType.description)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(red: 0.22, green: 0.29, blue: 0.38))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(tileGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
                            .blendMode(.overlay)
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.35 : 0.18),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    )
            )
            .shadow(
                color: accentColor.opacity(isSelected ? 0.35 : 0.15),
                radius: isSelected ? 16 : 8,
                x: 0,
                y: isSelected ? 12 : 6
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(accentColor)
                        )
                        .offset(x: -6, y: 6)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    private var tileGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(isSelected ? 0.55 : 0.18),
                Color.white.opacity(isSelected ? 0.2 : 0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var borderColor: Color {
        isSelected ? accentColor.opacity(0.9) : accentColor.opacity(0.4)
    }
}
