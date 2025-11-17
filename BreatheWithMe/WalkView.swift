//
//  WalkView.swift
//  BreatheWithMe
//
//  A green-accented hub for mindful walks with quick actions for insights,
//  sounds, and sessions. Styled to mirror FocusView.
//

import SwiftUI
import UIKit

struct WalkView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showProfile = false
    @State private var highlightedAction: WalkAction?
    @State private var showNoiseSettings = false
    @StateObject private var noiseGenerator = NoiseGenerator()

    private enum WalkAction {
        case insights, sounds, session
    }

    private let accentColor = Color(red: 0.32, green: 0.72, blue: 0.55)

    private var themeColors: ProfileTheme.Colors {
        themeManager.themeColors(for: systemColorScheme)
    }

    private var usesDarkAppearance: Bool {
        themeManager.colorScheme(for: systemColorScheme) == .dark
    }

    private var controlSurfaceColor: Color {
        usesDarkAppearance ? themeColors.cardBackground.opacity(0.72) : themeColors.cardBackground.opacity(0.96)
    }

    private var controlBorderColor: Color {
        usesDarkAppearance ? Color.white.opacity(0.18) : themeColors.separator.opacity(0.82)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                themeColors.backgroundTop,
                themeColors.backgroundBottom
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func functionalButtonBackground(
        isActive: Bool,
        usesAccentFillWhenInactive: Bool = false,
        cornerRadius: CGFloat = 18
    ) -> some View {
        let wantsAccentFill = isActive || usesAccentFillWhenInactive

        let fillColors: [Color] = wantsAccentFill
        ? [
            accentColor.opacity(isActive ? 0.55 : 0.35),
            accentColor.opacity(isActive ? 0.25 : 0.18)
        ]
        : [
            controlSurfaceColor.opacity(usesDarkAppearance ? 1.0 : 0.95),
            controlSurfaceColor.opacity(usesDarkAppearance ? 0.75 : 0.8)
        ]

        let strokeColors: [Color] = wantsAccentFill
        ? [
            accentColor.opacity(1.0),
            accentColor.opacity(isActive ? 0.5 : 0.35)
        ]
        : [
            controlBorderColor.opacity(0.85),
            controlBorderColor.opacity(0.3)
        ]

        let shadowOpacity = usesDarkAppearance ? (isActive ? 0.55 : 0.4) : (isActive ? 0.22 : 0.15)
        let accentGlowOpacity = isActive ? 0.35 : (usesAccentFillWhenInactive ? 0.15 : 0.0)

        return RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: fillColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: strokeColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: wantsAccentFill ? 1.5 : 1
                    )
            )
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: isActive ? 14 : 8,
                x: 0,
                y: isActive ? 10 : 5
            )
            .shadow(
                color: accentColor.opacity(accentGlowOpacity),
                radius: isActive ? 18 : 10,
                x: 0,
                y: isActive ? 10 : 4
            )
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Walk")
                .font(.system(size: 34, weight: .light, design: .default))
                .foregroundColor(themeColors.primaryText)

            Text("Mindful steps with fresh air")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(themeColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 52)
    }

    private var heroCard: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        accentColor.opacity(0.9),
                        accentColor.opacity(0.55)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(usesDarkAppearance ? 0.22 : 0.45), lineWidth: 1.2)
            )
            .shadow(color: accentColor.opacity(0.35), radius: 24, x: 0, y: 14)
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Step into a calmer rhythm")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Pair ambient sounds, start a focused walk, and review your insights.")
                        .font(.system(size: 15, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 24)
                }
            )
            .frame(height: 220)
            .padding(.horizontal, 24)
    }

    private func actionButton(
        _ action: WalkAction,
        icon: String,
        title: String,
        subtitle: String? = nil,
        isWide: Bool = false
    ) -> some View {
        let isActive = highlightedAction == action
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                highlightedAction = action
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(themeColors.secondaryText)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.85)
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, isWide ? 22 : 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                functionalButtonBackground(
                    isActive: isActive,
                    usesAccentFillWhenInactive: isWide,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var soundsButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showNoiseSettings = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: noiseGenerator.isEnabled ? "speaker.wave.2.fill" : "speaker.slash")
                    .font(.system(size: 16))
                Text("Sounds")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(themeColors.primaryText)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                functionalButtonBackground(
                    isActive: noiseGenerator.isEnabled,
                    usesAccentFillWhenInactive: false,
                    cornerRadius: 22
                )
            )
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var actionGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                actionButton(
                    .insights,
                    icon: "sparkles",
                    title: "Insights",
                    subtitle: "Trends & streaks"
                )
                soundsButton
            }
            actionButton(
                .session,
                icon: "play.fill",
                title: "Session",
                subtitle: "Start a mindful walk",
                isWide: true
            )
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var infoMessageOverlay: some View {
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
    
    @ViewBuilder
    private var noiseSettingsOverlay: some View {
        if showNoiseSettings {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNoiseSettings = false
                        }
                    }
                NoiseOptionsModal(
                    isPresented: $showNoiseSettings,
                    noiseGenerator: noiseGenerator,
                    accentColor: accentColor,
                    isRunning: true,
                    title: "Walk Sounds"
                )
                .transition(.scale.combined(with: .opacity))
            }
            .zIndex(2)
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: 24) {
                header

                heroCard

                Spacer()

                actionGrid
                    .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .swipeDownToOpenProfile {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                showProfile = true
            }
        }
        .topSlideCover(isPresented: $showProfile) {
            ProfileView(
                onDismiss: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        showProfile = false
                    }
                },
                isPresented: $showProfile
            )
            .environmentObject(themeManager)
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view.toolbar(showProfile ? .hidden : .visible, for: .tabBar)
            } else {
                view
            }
        }
        .overlay(infoMessageOverlay)
        .overlay(noiseSettingsOverlay)
        .onChange(of: showNoiseSettings) { isPresented in
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": isPresented]
            )
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .soundModalVisibilityDidChange,
                object: nil,
                userInfo: ["isPresented": false]
            )
        }
    }
}

#Preview {
    WalkView()
        .environmentObject(AppThemeManager())
}
