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
    }
}
