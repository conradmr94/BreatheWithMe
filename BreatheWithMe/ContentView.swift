//
//  ContentView.swift
//  BreatheWithMe
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    private let maxTabIndex = 2

    // Swipe tuning: keep these fairly high so precise UI drags don't trigger
    private let minHorizontalFlick: CGFloat = 220   // use predictedEndTranslation.width
    private let maxVerticalDrift: CGFloat   = 80    // ignore "diagonal" swipes

    var body: some View {
        let globalSwipe = DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { value in
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

        return TabView(selection: $selectedTab) {
            BreatheView()
                .tabItem { Label("Breathe", systemImage: "wind") }
                .tag(0)

            FocusView()
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(1)

            SleepView()
                .tabItem { Label("Sleep", systemImage: "moon.stars.fill") }
                .tag(2)
        }
        .accentColor(Color(red: 0.65, green: 0.8, blue: 0.92))
        .onAppear { updateTabColors(for: selectedTab) }
        .onChange(of: selectedTab) { updateTabColors(for: $0) }
        // IMPORTANT: simultaneous so child gestures still work.
        .simultaneousGesture(globalSwipe)
        .apply { view in
            if #available(iOS 16.0, *) {
                view
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarColorScheme(selectedTab == 2 ? .dark : .light, for: .tabBar)
            } else { view }
        }
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

    /// Dynamically update unselected tab icon/text color
    private func updateTabColors(for tab: Int) {
        if tab == 2 {
            UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.9, alpha: 1.0)
        } else {
            UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
        }
    }
}

// Helper extension for conditional view modifiers
extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}

#Preview { ContentView() }
