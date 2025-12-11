//
//  AppThemeManager.swift
//  BreatheWithMe
//
//  Created to share theme across the entire app
//

import SwiftUI
import UIKit

class AppThemeManager: ObservableObject {
    @AppStorage("profileThemeRawValue") var profileThemeRawValue: String = ProfileTheme.light.rawValue {
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
        var themeValue = profileThemeRawValue
        if themeValue == "white" {
            themeValue = "light"
        }
        
        if let theme = ProfileTheme(rawValue: themeValue) {
            // If we migrated, update the stored value
            if profileThemeRawValue == "white" {
                profileThemeRawValue = "light"
            }
            return theme
        }
        return .light
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

// MARK: - Analytics Palette Helpers
struct AnalyticsPalette {
    let colors: ProfileTheme.Colors
    let usesDarkAppearance: Bool
    
    var primaryText: Color { colors.primaryText }
    var secondaryText: Color { colors.secondaryText }
    var subtleText: Color { colors.subtleText }
    var accent: Color { colors.accent }
    var accentSoft: Color { colors.accent.opacity(usesDarkAppearance ? 0.25 : 0.12) }
    var highlight: Color { colors.highlight }
    var cardBackground: Color { colors.cardBackground }
    var cardShadow: Color { colors.cardShadow }
    var separator: Color { colors.separator }
    
    func elevatedAccent(opacity: Double = 0.18) -> Color {
        colors.accent.opacity(usesDarkAppearance ? 0.28 : opacity)
    }
}

private struct AnalyticsPaletteKey: EnvironmentKey {
    static let defaultValue = AnalyticsPalette(
        colors: ProfileTheme.light.colors(for: .light),
        usesDarkAppearance: false
    )
}

extension EnvironmentValues {
    var analyticsPalette: AnalyticsPalette {
        get { self[AnalyticsPaletteKey.self] }
        set { self[AnalyticsPaletteKey.self] = newValue }
    }
}

extension View {
    func analyticsCardStyle(_ palette: AnalyticsPalette, cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 10, shadowYOffset: CGFloat = 5) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(palette.cardBackground)
                .shadow(color: palette.cardShadow, radius: shadowRadius, x: 0, y: shadowYOffset)
        )
    }
}

