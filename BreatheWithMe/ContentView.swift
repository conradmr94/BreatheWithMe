//
//  ContentView.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BreatheView()
                .tabItem {
                    Label("Breathe", systemImage: "wind")
                }
            
            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }
            
            SleepView()
                .tabItem {
                    Label("Sleep", systemImage: "moon.stars.fill")
                }
        }
        .accentColor(Color(red: 0.65, green: 0.8, blue: 0.92))
    }
}

#Preview {
    ContentView()
}

