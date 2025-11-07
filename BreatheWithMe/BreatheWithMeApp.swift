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
    init() {
        // Set up notification delegate to handle background notifications
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

