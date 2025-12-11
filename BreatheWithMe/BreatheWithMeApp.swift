//
//  BreatheWithMeApp.swift
//  BreatheWithMe
//
//  Created on 10/15/2025.
//

import SwiftUI
import UserNotifications

@main
struct BreatheWithMeApp: App {
    @StateObject private var themeManager = AppThemeManager()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Set up notification delegate to handle background notifications
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        _ = AlarmManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // App became active - check if alarm should be showing
                print("📱 App became active")
                checkPendingAlarm()
            case .background:
                print("📱 App entered background")
            case .inactive:
                print("📱 App became inactive")
            @unknown default:
                break
            }
        }
    }
    
    private func checkPendingAlarm() {
        // If an alarm is active in the manager, it will already be showing
        // This ensures the UI updates when coming from background
        if AlarmManager.shared.isAlarmActive {
            print("✅ Alarm is active - UI should be showing")
        }
    }
}
