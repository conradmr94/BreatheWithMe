//
//  ContentView.swift
//  BreatheWithMe
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            BreatheView()
                .tabItem {
                    Label("Breathe", systemImage: "wind")
                }
                .tag(0)
            
            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
                .tag(1)
            
            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.stars.fill")
                }
                .tag(2)
        }
        .accentColor(Color(red: 0.65, green: 0.8, blue: 0.92)) // Light bluish gray
        .onAppear {
            updateTabColors(for: selectedTab)
        }
        .onChange(of: selectedTab) { newValue in
            updateTabColors(for: newValue)
        }
        .apply { view in
            if #available(iOS 16.0, *) {
                view
                    .toolbarBackground(.visible, for: .tabBar)
                    .toolbarColorScheme(selectedTab == 2 ? .dark : .light, for: .tabBar)
            } else {
                view
            }
        }
    }
    
    /// Dynamically update unselected tab icon/text color
    private func updateTabColors(for tab: Int) {
        if tab == 2 {
            // When Sleep tab selected — make others lighter than usual
            UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.9, alpha: 1.0)
        } else {
            // Default gray for unselected items
            UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
        }
    }
}

// Helper extension for conditional view modifiers
extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }
}

#Preview {
    ContentView()
}
