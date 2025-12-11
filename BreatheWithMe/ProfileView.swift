//
//  ProfileView.swift
//  BreatheWithMe
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    var onDismiss: (() -> Void)? = nil
    var isPresented: Binding<Bool>? = nil
    @StateObject private var statsManager = UserStatsManager()
    @StateObject private var sessionManager = SessionManager.shared
    
    @AppStorage("installDateTimestamp") private var installDateTimestamp: Double = 0
    @State private var showSettings = false
    
    // Profile picture state
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    @State private var showDefaultPictureOptions = false
    @State private var selectedDefaultIcon: String?
    
    // Profile name state
    @State private var userName: String = "Profile"
    @State private var isEditingName = false
    @State private var tempUserName: String = ""
    
    // Default profile picture options
    let defaultIcons = [
        "person.circle.fill",
        "face.smiling.fill",
        "figure.mind.and.body",
        "heart.circle.fill",
        "sun.max.fill",
        "moon.stars.fill",
        "leaf.fill",
        "flame.fill"
    ]

    private var themeColors: ProfileTheme.Colors { themeManager.themeColors(for: systemColorScheme) }
    
    private var profileThemeBinding: Binding<ProfileTheme> {
        Binding(
            get: { themeManager.currentTheme },
            set: { newTheme in
                themeManager.profileThemeRawValue = newTheme.rawValue
            }
        )
    }

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                        VStack(spacing: 24) {
                        // Invisible anchor at the top for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("top")
                            .padding(.top, -8)
                        
                    // Profile Summary Card
                    VStack {
                        HStack(alignment: .center, spacing: 24) {
                            VStack(alignment: .center, spacing: 12) {
                                Menu {
                                    Button(action: { showImagePicker = true }) {
                                        Label("Choose from Photos", systemImage: "photo.on.rectangle")
                                    }
                                    
                                    Button(action: { showDefaultPictureOptions = true }) {
                                        Label("Choose Default Icon", systemImage: "person.crop.circle.badge.checkmark")
                                    }
                                } label: {
                                    ZStack(alignment: .bottomTrailing) {
                                        Group {
                                            if let profileImage = profileImage {
                                                Image(uiImage: profileImage)
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                Image(systemName: selectedDefaultIcon ?? "person.circle.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(themeColors.accent)
                                            }
                                        }
                                        .frame(width: 96, height: 96)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(themeColors.accent, lineWidth: 3)
                                        )
                                        
                                        Circle()
                                            .fill(themeColors.accent)
                                            .frame(width: 28, height: 28)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(themeColors.cardBackground)
                                            )
                                            .offset(x: 6, y: 6)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                VStack(spacing: 6) {
                                    if isEditingName {
                                        HStack(spacing: 8) {
                                            TextField("Enter your name", text: $tempUserName)
                                                .font(.system(size: 26, weight: .light, design: .default))
                                                .foregroundColor(themeColors.primaryText)
                                                .multilineTextAlignment(.center)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .frame(maxWidth: 220)
                                            
                                            Button(action: {
                                                if !tempUserName.trimmingCharacters(in: .whitespaces).isEmpty {
                                                    userName = tempUserName
                                                    saveUserName(tempUserName)
                                                }
                                                isEditingName = false
                                            }) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 26))
                                                    .foregroundColor(themeColors.accent)
                                            }
                                        }
                                    } else {
                                        Button(action: {
                                            tempUserName = userName
                                            isEditingName = true
                                        }) {
                                            VStack(spacing: 4) {
                                                Text(userName)
                                                    .font(.system(size: 30, weight: .semibold, design: .default))
                                                    .foregroundColor(themeColors.primaryText)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    
                                    Text(statsManager.motivationalMessage)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(themeColors.secondaryText)
                                    
                                    Text(todayString)
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(themeColors.subtleText)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(themeColors.separator.opacity(0.7))
                                .frame(width: 1, height: 120)
                                .cornerRadius(1)
                            
                            ProfileStatsBlock(stats: summaryStats, colors: themeColors)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(themeColors.cardBackground)
                            .shadow(color: themeColors.cardShadow, radius: 25, x: 0, y: 16)
                    )
                    
                    // Activity Overview Card
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink(destination: ActivityCalendarView()) {
                            HStack {
                                Label("Current Streak", systemImage: "flame.fill")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(themeColors.primaryText)
                                Spacer()
                                Text(statsManager.currentStreak == 0 ? "—" : "\(statsManager.currentStreak) \(statsManager.currentStreak == 1 ? "day" : "days")")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(statsManager.currentStreak >= 3 ? themeColors.highlight : themeColors.primaryText)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeColors.subtleText)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tint(themeColors.accent)
                        
                        Divider()
                            .background(themeColors.separator)
                        
                        HStack {
                            Label("Total Sessions", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(themeColors.primaryText)
                            Spacer()
                            Text("\(statsManager.totalSessions)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(themeColors.primaryText)
                        }
                        
                        Divider()
                            .background(themeColors.separator)
                        
                        HStack {
                            Label("Total Time", systemImage: "clock.fill")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(themeColors.primaryText)
                            Spacer()
                            Text(statsManager.totalSessions > 0 ? statsManager.totalTimeFormatted : "—")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(themeColors.primaryText)
                        }
                        
                        Divider()
                            .background(themeColors.separator)
                        
                        HStack {
                            Label("Favorite Activity", systemImage: "star.fill")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(themeColors.primaryText)
                            Spacer()
                            Text(statsManager.favoriteActivity)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(themeColors.primaryText)
                        }
                    }
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(themeColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeColors.cardBackground)
                            .shadow(color: themeColors.cardShadow, radius: 20, x: 0, y: 10)
                    )
                    
                    // Additional Stats Card
                    if statsManager.totalSessions > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("More Stats")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(themeColors.secondaryText)
                            
                            HStack {
                                Text("Active Days")
                                Spacer()
                                Text("\(statsManager.totalActiveDays)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeColors.primaryText)
                            }
                            
                            HStack {
                                Text("Longest Streak")
                                Spacer()
                                Text("\(statsManager.longestStreak) \(statsManager.longestStreak == 1 ? "day" : "days")")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeColors.primaryText)
                            }
                            
                            HStack {
                                Text("Avg. Session")
                                Spacer()
                                Text(statsManager.averageSessionDurationFormatted)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeColors.primaryText)
                            }
                            
                            HStack {
                                Text("This Week")
                                Spacer()
                                Text("\(statsManager.sessionsThisWeek) sessions")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeColors.primaryText)
                            }
                        }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(themeColors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeColors.cardBackground)
                                .shadow(color: themeColors.cardShadow, radius: 20, x: 0, y: 10)
                        )
                    }

                    // Bottom stats shortcuts
                    VStack(spacing: 10) {                        
                        NavigationLink(destination: AnalyticsView()) {
                            HStack {
                                Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(themeColors.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(themeColors.subtleText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(themeColors.cardBackground)
                                    .shadow(color: themeColors.cardShadow, radius: 12, x: 0, y: 6)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tint(themeColors.accent)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
                }
                .onAppear {
                    loadProfileImage()
                    loadUserName()
                    loadSelectedIcon()
                    // Always scroll to top when profile opens
                    proxy.scrollTo("top", anchor: .top)
                }
                .onChange(of: isPresented?.wrappedValue) { newValue in
                    // Scroll to top whenever the profile becomes visible
                    if newValue == true {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, onImageSelected: { image in
                    saveProfileImage(image)
                })
            }
            .sheet(isPresented: $showDefaultPictureOptions) {
                DefaultIconPicker(
                    selectedIcon: $selectedDefaultIcon,
                    icons: defaultIcons,
                    onSelect: { icon in
                        selectedDefaultIcon = icon
                        profileImage = nil // Clear custom image
                        saveSelectedIcon(icon)
                        showDefaultPictureOptions = false
                    }
                )
            }
            .sheet(isPresented: $showSettings) {
                ProfileSettingsView(selectedTheme: profileThemeBinding)
                    .environmentObject(themeManager)
            }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeColors.primaryText)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themeColors.primaryText)
                    }
                }
            }
            .modifier(ToolbarBackgroundModifier())
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let t = value.translation
                        // Require a larger upward swipe (180) and stricter horizontal tolerance (50)
                        // to prevent accidental dismissal while scrolling
                        if t.height < -180 && abs(t.width) < 50 {
                            onDismiss?()
                        }
                    }
            )
        }
    }
    
    // MARK: - Profile Image Persistence
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "profileImage"),
           let uiImage = UIImage(data: imageData) {
            profileImage = uiImage
        }
    }
    
    private func saveProfileImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "profileImage")
            // Clear selected icon when custom image is set
            UserDefaults.standard.removeObject(forKey: "selectedDefaultIcon")
        }
    }
    
    // MARK: - Default Icon Persistence
    private func loadSelectedIcon() {
        if let icon = UserDefaults.standard.string(forKey: "selectedDefaultIcon") {
            selectedDefaultIcon = icon
        }
    }
    
    private func saveSelectedIcon(_ icon: String) {
        UserDefaults.standard.set(icon, forKey: "selectedDefaultIcon")
        // Clear custom image when icon is selected
        UserDefaults.standard.removeObject(forKey: "profileImage")
    }
    
    // MARK: - User Name Persistence
    private func loadUserName() {
        if let name = UserDefaults.standard.string(forKey: "userName"), !name.isEmpty {
            userName = name
        }
    }
    
    private func saveUserName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "userName")
    }

    private var installDate: Date {
        if installDateTimestamp == 0 {
            let now = Date()
            installDateTimestamp = now.timeIntervalSince1970
            return now
        }
        return Date(timeIntervalSince1970: installDateTimestamp)
    }
    
    private var daysWithUs: Int {
        max(Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0, 0)
    }
    
    private var withUsValue: String {
        let days = daysWithUs
        if days < 7 {
            return "\(days)d"
        }
        let weeks = days / 7
        if weeks < 8 {
            return "\(weeks) wk"
        }
        let months = days / 30
        if months < 12 {
            return "\(months) mo"
        }
        let years = max(days / 365, 1)
        return "\(years) yr"
    }
    
    private var averageSleepHours: Double? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let sessions = sessionManager.sleepSessions(from: cutoff, to: Date())
        guard !sessions.isEmpty else { return nil }
        let totalSeconds = sessions.reduce(0) { $0 + $1.durationSeconds }
        return Double(totalSeconds) / Double(sessions.count) / 3600.0
    }
    
    private var averageSleepDisplay: String {
        guard let hours = averageSleepHours else { return "—" }
        return String(format: "%0.1fh", hours)
    }
    
    private var dayStreakDisplay: String {
        let streak = max(statsManager.currentStreak, 0)
        return streak == 0 ? "0" : "\(streak)"
    }
    
    private var summaryStats: [ProfileStatItem] {
        [
            ProfileStatItem(value: dayStreakDisplay, label: "Day streak"),
            ProfileStatItem(value: averageSleepDisplay, label: "Avg sleep"),
            ProfileStatItem(value: withUsValue, label: "With us")
        ]
    }
}

// MARK: - Profile Theme Model
enum ProfileTheme: String, CaseIterable, Identifiable {
    case `default`
    case dark
    case light
    
    struct Colors {
        let accent: Color
        let primaryText: Color
        let secondaryText: Color
        let subtleText: Color
        let highlight: Color
        let cardBackground: Color
        let cardShadow: Color
        let backgroundTop: Color
        let backgroundBottom: Color
        let separator: Color
    }
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .default: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }
    
    var symbolName: String {
        switch self {
        case .default: return "circle.lefthalf.filled"
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
    
    func colors(for systemColorScheme: ColorScheme) -> Colors {
        switch self {
        case .default:
            return systemColorScheme == .dark ? darkColors : defaultLightColors
        case .dark:
            return darkColors
        case .light:
            return pureLightColors
        }
    }
    
    // Original BreatheView colors (for system theme when light)
    private var defaultLightColors: Colors {
        Colors(
            accent: Color(red: 0.60, green: 0.76, blue: 0.92),
            primaryText: Color(red: 0.20, green: 0.28, blue: 0.37),
            secondaryText: Color(red: 0.42, green: 0.50, blue: 0.59),
            subtleText: Color(red: 0.56, green: 0.63, blue: 0.72),
            highlight: Color(red: 0.99, green: 0.72, blue: 0.42),
            cardBackground: Color.white,
            cardShadow: Color.black.opacity(0.08),
            backgroundTop: Color(red: 0.94, green: 0.97, blue: 1.0),
            backgroundBottom: Color(red: 0.87, green: 0.92, blue: 0.98),
            separator: Color(red: 0.89, green: 0.93, blue: 0.97)
        )
    }
    
    // Light theme colors (matches system light theme)
    private var pureLightColors: Colors {
        Colors(
            accent: Color(red: 0.60, green: 0.76, blue: 0.92),
            primaryText: Color(red: 0.20, green: 0.28, blue: 0.37),
            secondaryText: Color(red: 0.42, green: 0.50, blue: 0.59),
            subtleText: Color(red: 0.56, green: 0.63, blue: 0.72),
            highlight: Color(red: 0.99, green: 0.72, blue: 0.42),
            cardBackground: Color.white,
            cardShadow: Color.black.opacity(0.08),
            backgroundTop: Color(red: 0.94, green: 0.97, blue: 1.0),
            backgroundBottom: Color(red: 0.87, green: 0.92, blue: 0.98),
            separator: Color(red: 0.89, green: 0.93, blue: 0.97)
        )
    }
    
    // Dark theme colors
    private var darkColors: Colors {
        Colors(
            accent: Color(red: 0.45, green: 0.68, blue: 0.95),
            primaryText: Color.white,
            secondaryText: Color.white.opacity(0.8),
            subtleText: Color.white.opacity(0.55),
            highlight: Color.orange,
            cardBackground: Color(red: 0.12, green: 0.15, blue: 0.2),
            cardShadow: Color.black.opacity(0.55),
            backgroundTop: Color(red: 0.04, green: 0.05, blue: 0.08),
            backgroundBottom: Color(red: 0.09, green: 0.11, blue: 0.16),
            separator: Color.white.opacity(0.18)
        )
    }
    
    // For backward compatibility - returns light colors by default
    var colors: Colors {
        defaultLightColors
    }

    func colorScheme(for systemColorScheme: ColorScheme) -> ColorScheme {
        switch self {
        case .default:
            return systemColorScheme
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
    
    // For backward compatibility
    var colorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
        default:
            return .light
        }
    }
}

// MARK: - Settings Sheet
struct ProfileSettingsView: View {
    @Binding var selectedTheme: ProfileTheme
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var themeManager: AppThemeManager
    @Environment(\.colorScheme) var systemColorScheme
    
    private var themeColors: ProfileTheme.Colors { themeManager.themeColors(for: systemColorScheme) }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColors.backgroundTop,
                        themeColors.backgroundBottom
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                List {
                    Section(header: Text("Theme")
                        .foregroundColor(themeColors.secondaryText)
                        .textCase(nil)) {
                        ForEach(ProfileTheme.allCases) { theme in
                            Button(action: {
                                selectedTheme = theme
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: theme.symbolName)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(themeColors.accent)
                                    Text(theme.displayName)
                                        .foregroundColor(themeColors.primaryText)
                                    Spacer()
                                    if selectedTheme == theme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(themeColors.accent)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(themeColors.cardBackground.opacity(0.6))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .modifier(ScrollContentBackgroundModifier())
                .background(Color.clear)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(themeColors.primaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(themeColors.accent)
                }
            }
        }
    }
}

// MARK: - Profile Summary Helpers
private struct ProfileStatItem: Identifiable {
    let id = UUID()
    let value: String
    let label: String
}

private struct ProfileStatsBlock: View {
    let stats: [ProfileStatItem]
    let colors: ProfileTheme.Colors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Rectangle()
                        .fill(colors.separator.opacity(0.7))
                        .frame(height: 1)
                        .cornerRadius(1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(stat.value)
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .foregroundColor(colors.primaryText)
                    Text(stat.label)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(colors.secondaryText)
                        .textCase(.none)
                }
            }
        }
    }
}

// MARK: - Default Icon Picker
struct DefaultIconPicker: View {
    @Binding var selectedIcon: String?
    let icons: [String]
    let onSelect: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            onSelect(icon)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color(red: 0.5, green: 0.6, blue: 0.7).opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? Color(red: 0.5, green: 0.6, blue: 0.7) : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.9, green: 0.94, blue: 0.98)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageSelected(uiImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Toolbar Background Modifier
struct ToolbarBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.toolbarBackground(.hidden, for: .navigationBar)
        } else {
            content
        }
    }
}

// MARK: - Scroll Content Background Modifier
struct ScrollContentBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
}

#Preview {
    ProfileView()
}

