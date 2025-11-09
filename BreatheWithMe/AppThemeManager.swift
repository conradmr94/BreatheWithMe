//
//  AppThemeManager.swift
//  BreatheWithMe
//
//  Created to share theme across the entire app
//

import SwiftUI
import UIKit

class AppThemeManager: ObservableObject {
    @AppStorage("profileThemeRawValue") var profileThemeRawValue: String = ProfileTheme.default.rawValue {
        didSet {
            objectWillChange.send()
        }
    }
    
    // System color scheme observer
    @Published private var systemColorScheme: ColorScheme = .light
    
    init() {
        // Initialize with current system color scheme
        updateSystemColorScheme()
        
        // Observe system color scheme changes
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSystemColorScheme()
        }
    }
    
    private func updateSystemColorScheme() {
        // Get the current system color scheme from the main window
        let newScheme: ColorScheme
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            newScheme = window.traitCollection.userInterfaceStyle == .dark ? .dark : .light
        } else {
            // Fallback to current trait collection
            newScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        }
        
        if newScheme != systemColorScheme {
            systemColorScheme = newScheme
            objectWillChange.send()
        }
    }
    
    // Call this method when the view appears or when trait collection changes
    func updateSystemColorScheme(from traitCollection: UITraitCollection) {
        let newScheme: ColorScheme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
        if newScheme != systemColorScheme {
            systemColorScheme = newScheme
            objectWillChange.send()
        }
    }
    
    var currentTheme: ProfileTheme {
        // Migrate old "white" theme to "light" for backward compatibility
        let themeValue = profileThemeRawValue == "white" ? "light" : profileThemeRawValue
        if let theme = ProfileTheme(rawValue: themeValue) {
            // If we migrated, update the stored value
            if profileThemeRawValue == "white" {
                profileThemeRawValue = "light"
            }
            return theme
        }
        return .default
    }
    
    func themeColors(for environmentColorScheme: ColorScheme) -> ProfileTheme.Colors {
        // Use environment color scheme if provided, otherwise use internal tracking
        currentTheme.colors(for: environmentColorScheme)
    }
    
    // Convenience accessor that uses internal system color scheme tracking
    var themeColors: ProfileTheme.Colors {
        currentTheme.colors(for: systemColorScheme)
    }
    
    func colorScheme(for environmentColorScheme: ColorScheme) -> ColorScheme {
        currentTheme.colorScheme(for: environmentColorScheme)
    }
    
    // Convenience accessor that uses internal system color scheme tracking
    var colorScheme: ColorScheme {
        currentTheme.colorScheme(for: systemColorScheme)
    }
}

