//
//  ContentView.swift
//  BreatheWithMe
//

import SwiftUI
import UIKit
import Combine

extension Notification.Name {
    static let soundModalVisibilityDidChange = Notification.Name("soundModalVisibilityDidChange")
}

struct ContentView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    @State private var selectedTab = 0
    private let maxTabIndex = 3
    @State private var isSoundModalPresented = false
    @AppStorage("focusLockUntilTimestamp") private var focusLockUntilTimestamp: Double = 0
    @State private var lockNow = Date()
    @State private var showUnlockFocusLockAlert = false
    private let focusLockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private static let focusLockTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    private static let focusLockRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    // Swipe tuning: keep these fairly high so precise UI drags don't trigger
    private let minHorizontalFlick: CGFloat = 220   // use predictedEndTranslation.width
    private let maxVerticalDrift: CGFloat   = 80    // ignore "diagonal" swipes

    var body: some View {
        let themeColors = themeManager.themeColors(for: systemColorScheme)
        let globalSwipe = DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { value in
                guard !isSoundModalPresented else { return }

                let dx = value.translation.width
                let dy = value.translation.height
                let pdx = value.predictedEndTranslation.width   // better proxy for flick velocity

                // Must be mostly horizontal
                guard abs(dy) < maxVerticalDrift else { return }

                // Use predicted end to require a quick flick, not a slow drag
                if pdx <= -minHorizontalFlick {
                    goToNextTab()
                } else if pdx >= minHorizontalFlick {
                    goToPreviousTab()
                } else {
                    // Optional: fallback to actual translation if user swipes slowly but decisively
                    if dx <= -minHorizontalFlick { goToNextTab() }
                    if dx >=  minHorizontalFlick { goToPreviousTab() }
                }
            }

        let tabContent = TabView(selection: $selectedTab) {
            BreatheView()
                .tabItem { Label("Breathe", systemImage: "wind") }
                .tag(0)

            WalkView()
                .tabItem { Label("Walk", systemImage: "figure.walk") }
                .tag(1)

            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(2)

            SleepView()
                .tabItem { Label("Sleep", systemImage: "moon.stars.fill") }
                .tag(3)
        }
        .accentColor(accentColor(for: selectedTab))
        .tint(accentColor(for: selectedTab))
        .onAppear { updateTabColors(for: selectedTab) }
        .onChange(of: selectedTab) { updateTabColors(for: $0) }
        .simultaneousGesture(globalSwipe)
        .onReceive(NotificationCenter.default.publisher(for: .soundModalVisibilityDidChange)) { notification in
            if let isPresented = notification.userInfo?["isPresented"] as? Bool {
                isSoundModalPresented = isPresented
            }
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarColorScheme(appColorScheme, for: .tabBar)
            } else { view }
        }

        return ZStack {
            tabContent
            if focusLockActive {
                focusLockOverlay
            }
        }
        .onAppear {
            // Update system color scheme when view appears
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                themeManager.updateSystemColorScheme(from: window.traitCollection)
            }
        }
        .onChange(of: systemColorScheme) { _ in
            // Update when system color scheme changes
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                themeManager.updateSystemColorScheme(from: window.traitCollection)
            }
            // Update tab colors when color scheme changes
            updateTabColors(for: selectedTab)
        }
        .onChange(of: themeManager.profileThemeRawValue) { _ in
            // Update tab colors when user manually changes theme in Profile settings
            updateTabColors(for: selectedTab)
        }
        .onReceive(focusLockTimer) { date in
            lockNow = date
            if focusLockUntilTimestamp > 0 && focusLockUntilTimestamp <= date.timeIntervalSince1970 {
                focusLockUntilTimestamp = 0
            }
        }
        .alert("Unlock early?", isPresented: $showUnlockFocusLockAlert) {
            Button("Unlock", role: .destructive) { releaseFocusLock() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Focus Lock keeps the app blocked until your scheduled wake time. Unlocking early will end the session now.")
        }
        .preferredColorScheme(appColorScheme)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColors.backgroundTop,
                    themeColors.backgroundBottom
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private var focusLockRemaining: TimeInterval {
        max(0, focusLockUntilTimestamp - lockNow.timeIntervalSince1970)
    }
    private var focusLockActive: Bool {
        focusLockRemaining > 0
    }
    private var focusLockEndDate: Date {
        Date(timeIntervalSince1970: focusLockUntilTimestamp)
    }
    private var focusLockCountdownText: String {
        let remaining = Int(focusLockRemaining)
        guard remaining > 0 else { return "00:00" }
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    private var focusLockEndDescription: String {
        guard focusLockActive else { return "" }
        let time = ContentView.focusLockTimeFormatter.string(from: focusLockEndDate)
        let relative = ContentView.focusLockRelativeFormatter.localizedString(for: focusLockEndDate, relativeTo: lockNow)
        return "Unlocks at \(time) (\(relative))"
    }
    @ViewBuilder
    private var focusLockOverlay: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
                Text("Focus Lock is on")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                Text(focusLockCountdownText)
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                if !focusLockEndDescription.isEmpty {
                    Text(focusLockEndDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                Button(action: { showUnlockFocusLockAlert = true }) {
                    Text("Unlock early")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(18)
                }
                .padding(.top, 12)
            }
            .padding(32)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: focusLockActive)
    }
    
    private func releaseFocusLock() {
        focusLockUntilTimestamp = 0
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // MARK: - Tab helpers
    private func goToNextTab() {
        guard selectedTab < maxTabIndex else { return }
        withAnimation(.easeInOut(duration: 0.2)) { selectedTab += 1 }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func goToPreviousTab() {
        guard selectedTab > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) { selectedTab -= 1 }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Get the accent color for a specific tab
    private func accentColor(for tab: Int) -> Color {
        switch tab {
        case 0: // Breathe - soft blue
            return Color(red: 0.60, green: 0.76, blue: 0.92)
        case 1: // Walk - light green
            return Color(red: 0.5, green: 0.8, blue: 0.65)
        case 2: // Focus - soft orange
            return Color(red: 0.9, green: 0.6, blue: 0.5)
        case 3: // Sleep - soft purple/blue
            return Color(red: 0.4, green: 0.5, blue: 0.8)
        default:
            let themeColors = themeManager.themeColors(for: systemColorScheme)
            return themeColors.accent
        }
    }
    
    /// Dynamically update tab bar colors based on selected tab
    private func updateTabColors(for tab: Int) {
        let themeColors = themeManager.themeColors(for: systemColorScheme)
        let selectedColor = accentColor(for: tab)
        
        // Set the selected tab color (tint)
        UITabBar.appearance().tintColor = UIColor(selectedColor)
        
        // Set the unselected tab color
        UITabBar.appearance().unselectedItemTintColor = UIColor(themeColors.secondaryText.opacity(0.6))
    }

    private var appColorScheme: ColorScheme {
        themeManager.colorScheme(for: systemColorScheme)
    }
}

// Helper extension for conditional view modifiers
extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}

#Preview { 
    ContentView()
        .environmentObject(AppThemeManager())
}
