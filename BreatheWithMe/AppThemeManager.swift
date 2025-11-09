//
//  AppThemeManager.swift
//  BreatheWithMe
//
//  Created to share theme across the entire app
//

import SwiftUI

class AppThemeManager: ObservableObject {
    @AppStorage("profileThemeRawValue") var profileThemeRawValue: String = ProfileTheme.default.rawValue {
        didSet {
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
    
    var themeColors: ProfileTheme.Colors {
        currentTheme.colors
    }
    
    var colorScheme: ColorScheme {
        currentTheme.colorScheme
    }
}

