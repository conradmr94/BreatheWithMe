//
//  ActivityCalendarView.swift
//  BreatheWithMe
//
//  Shows a calendar view with days that have activity highlighted
//

import SwiftUI

struct ActivityCalendarView: View {
    @StateObject private var statsManager = UserStatsManager()
    @State private var selectedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showingDayStats = false
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with streak info
                HStack(spacing: 12) {
                    // Current Streak Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(statsManager.currentStreak >= 3 ? Color.orange : Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("Current Streak")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                .textCase(.uppercase)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(statsManager.currentStreak)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(statsManager.currentStreak >= 3 ? Color.orange : Color(red: 0.2, green: 0.3, blue: 0.4))
                            Text(statsManager.currentStreak == 1 ? "day" : "days")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .padding(.bottom, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    )
                    
                    // Longest Streak Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("Best")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                .textCase(.uppercase)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(statsManager.longestStreak)")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            Text(statsManager.longestStreak == 1 ? "day" : "days")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .padding(.bottom, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 20)
                
                // Month selector
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                            )
                    }
                    
                    Spacer()
                    
                    Text(monthYearString)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(canGoToNextMonth ? Color(red: 0.4, green: 0.5, blue: 0.6) : Color.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                            )
                    }
                    .disabled(!canGoToNextMonth)
                }
                .padding(.horizontal, 20)
                
                // Calendar grid
                VStack(spacing: 16) {
                    // Days of week header
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                .textCase(.uppercase)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(daysInMonth, id: \.self) { date in
                            if let date = date {
                                DayCell(
                                    date: date,
                                    isToday: calendar.isDateInToday(date),
                                    hasActivity: hasActivityOn(date: date),
                                    activityCount: sessionCountOn(date: date),
                                    isCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
                                )
                                .onTapGesture {
                                    selectedDate = date
                                    showingDayStats = true
                                }
                            } else {
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // Activity legend
                VStack(alignment: .leading, spacing: 16) {
                    Text("Activity Rings")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.45))
                    
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .trim(from: 0.0, to: 0.33)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.5, green: 0.75, blue: 0.95)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                                    )
                                    .frame(width: 28, height: 28)
                                    .rotationEffect(.degrees(-90))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("1-2 sessions")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.45))
                                Text("33% ring")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .trim(from: 0.0, to: 0.66)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(red: 0.5, green: 0.8, blue: 1.0), Color(red: 0.3, green: 0.7, blue: 0.95)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                                    )
                                    .frame(width: 28, height: 28)
                                    .rotationEffect(.degrees(-90))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("3-4 sessions")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.45))
                                Text("66% ring")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                        }
                        
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .trim(from: 0.0, to: 1.0)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.0, green: 0.5, blue: 0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                                    )
                                    .frame(width: 28, height: 28)
                                    .rotationEffect(.degrees(-90))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("5+ sessions")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.45))
                                Text("Complete ring")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // Stats summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        Text("This Month")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.45))
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.9))
                                    .frame(width: 24)
                                Text("Active Days")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            }
                            Spacer()
                            Text("\(activeDaysThisMonth)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                        }
                        
                        Divider()
                            .background(Color(red: 0.85, green: 0.9, blue: 0.95))
                        
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.5))
                                    .frame(width: 24)
                                Text("Total Sessions")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            }
                            Spacer()
                            Text("\(sessionsThisMonth)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                        }
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
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
        .navigationTitle("Activity Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDayStats) {
            if let date = selectedDate {
                DayStatsDetailView(date: date, statsManager: statsManager)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var canGoToNextMonth: Bool {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? Date()
        return calendar.compare(nextMonth, to: Date(), toGranularity: .month) != .orderedDescending
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        let monthLastDay = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)!
        
        var days: [Date?] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate <= monthLastDay {
            // Add the date if it's in the selected month, otherwise add nil for empty cells
            if calendar.isDate(currentDate, equalTo: selectedMonth, toGranularity: .month) {
                days.append(currentDate)
            } else if days.isEmpty || days.count % 7 != 0 {
                // Add empty cells for days before the month starts
                days.append(nil)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            
            // Stop if we've filled complete weeks after the month ends
            if currentDate > monthLastDay && days.count % 7 == 0 {
                break
            }
        }
        
        // Pad the end to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private var activeDaysThisMonth: Int {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        let sessionsInMonth = statsManager.sessionHistory.filter {
            $0.date >= startOfMonth && $0.date < endOfMonth
        }
        
        let uniqueDays = Set(sessionsInMonth.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }
    
    private var sessionsThisMonth: Int {
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.start ?? selectedMonth
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        
        return statsManager.sessionHistory.filter {
            $0.date >= startOfMonth && $0.date < endOfMonth
        }.count
    }
    
    // MARK: - Helper Methods
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            // Only allow navigation up to current month
            if calendar.compare(newMonth, to: Date(), toGranularity: .month) != .orderedDescending {
                selectedMonth = newMonth
            }
        }
    }
    
    private func hasActivityOn(date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        return statsManager.sessionHistory.contains { session in
            calendar.isDate(session.date, inSameDayAs: dayStart)
        }
    }
    
    private func sessionCountOn(date: Date) -> Int {
        let dayStart = calendar.startOfDay(for: date)
        return statsManager.sessionHistory.filter { session in
            calendar.isDate(session.date, inSameDayAs: dayStart)
        }.count
    }
}

// MARK: - Day Stats Detail View
struct DayStatsDetailView: View {
    let date: Date
    @ObservedObject var statsManager: UserStatsManager
    @Environment(\.dismiss) var dismiss
    
    private let calendar = Calendar.current
    
    private var sessionsForDay: [SessionRecord] {
        statsManager.sessionHistory.filter { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }.sorted { $0.date > $1.date }
    }
    
    private var totalTimeSeconds: Int {
        sessionsForDay.reduce(0) { $0 + $1.durationSeconds }
    }
    
    private var sessionsByType: [(type: SessionRecord.ActivityType, count: Int, time: Int)] {
        let breathe = sessionsForDay.filter { $0.activityType == .breathe }
        let focus = sessionsForDay.filter { $0.activityType == .focus }
        let rest = sessionsForDay.filter { $0.activityType == .rest }
        let sleep = sessionsForDay.filter { $0.activityType == .sleep }
        
        return [
            (.breathe, breathe.count, breathe.reduce(0) { $0 + $1.durationSeconds }),
            (.focus, focus.count, focus.reduce(0) { $0 + $1.durationSeconds }),
            (.rest, rest.count, rest.reduce(0) { $0 + $1.durationSeconds }),
            (.sleep, sleep.count, sleep.reduce(0) { $0 + $1.durationSeconds })
        ].filter { $0.count > 0 }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Date header
                    VStack(spacing: 12) {
                        Text(formatDate(date))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                        
                        if calendar.isDateInToday(date) {
                            Text("TODAY")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.white)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.0, green: 0.5, blue: 0.9)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Main stats cards
                    HStack(spacing: 12) {
                        // Total Sessions Card
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.9))
                            
                            Text("\(sessionsForDay.count)")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                            
                            Text("SESSIONS")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        )
                        
                        // Total Time Card
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.5))
                            
                            Text(formatTime(seconds: totalTimeSeconds))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            
                            Text("TOTAL TIME")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity breakdown
                    if !sessionsByType.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.pie.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                Text("Activity Summary")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                            
                            VStack(spacing: 14) {
                                ForEach(sessionsByType, id: \.type) { item in
                                    VStack(spacing: 10) {
                                        HStack {
                                            HStack(spacing: 12) {
                                                // Icon circle
                                                ZStack {
                                                    Circle()
                                                        .fill(colorForActivity(item.type).opacity(0.15))
                                                        .frame(width: 44, height: 44)
                                                    Image(systemName: iconForActivity(item.type))
                                                        .font(.system(size: 20, weight: .semibold))
                                                        .foregroundColor(colorForActivity(item.type))
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.type.rawValue)
                                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                                    Text("\(item.count) session\(item.count == 1 ? "" : "s")")
                                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Text(formatTime(seconds: item.time))
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(colorForActivity(item.type))
                                        }
                                        
                                        // Progress bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                // Background bar
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color(red: 0.92, green: 0.94, blue: 0.96))
                                                    .frame(height: 8)
                                                
                                                // Progress bar
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                colorForActivity(item.type).opacity(0.8),
                                                                colorForActivity(item.type)
                                                            ],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(
                                                        width: geometry.size.width * CGFloat(item.time) / CGFloat(max(totalTimeSeconds, 1)),
                                                        height: 8
                                                    )
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }

                    
                    // Additional insights - Average session duration
                    if !sessionsForDay.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                Text("Insights")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                            
                            HStack(spacing: 12) {
                                // Average session duration
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("AVG SESSION")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                        .textCase(.uppercase)
                                    
                                    Text(formatTime(seconds: totalTimeSeconds / max(sessionsForDay.count, 1)))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                                    
                                    Text("per session")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                
                                // Most active type
                                if let topActivity = sessionsByType.max(by: { $0.count < $1.count }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("TOP ACTIVITY")
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(Color(red: 0.45, green: 0.55, blue: 0.65))
                                            .textCase(.uppercase)
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: iconForActivity(topActivity.type))
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundColor(colorForActivity(topActivity.type))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(topActivity.type.rawValue)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.35))
                                                Text("\(topActivity.count) times")
                                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(18)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // No activity message
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.5, green: 0.6, blue: 0.7).opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            VStack(spacing: 6) {
                                Text("No Activity")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                
                                Text("No sessions recorded on this day")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                        }
                        .padding(.vertical, 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
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
            .navigationTitle("Day Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm", minutes)
        } else {
            return "\(secs)s"
        }
    }
    
    private func iconForActivity(_ type: SessionRecord.ActivityType) -> String {
        switch type {
        case .breathe:
            return "wind"
        case .focus:
            return "timer"
        case .rest:
            return "cup.and.saucer.fill"
        case .sleep:
            return "moon.fill"
        }
    }
    
    private func colorForActivity(_ type: SessionRecord.ActivityType) -> Color {
        switch type {
        case .breathe:
            return Color(red: 0.4, green: 0.7, blue: 0.9)
        case .focus:
            return Color(red: 0.9, green: 0.5, blue: 0.3)
        case .rest:
            return Color(red: 0.5, green: 0.8, blue: 0.5)
        case .sleep:
            return Color(red: 0.6, green: 0.5, blue: 0.8)
        }
    }
}

// MARK: - Day Cell View
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let hasActivity: Bool
    let activityCount: Int
    let isCurrentMonth: Bool
    
    @State private var isPressed = false
    
    // Activity completion percentage (0.0 to 1.0)
    private var activityProgress: Double {
        if !hasActivity {
            return 0.0
        }
        // Map activity count to progress (1-2 = 33%, 3-4 = 66%, 5+ = 100%)
        if activityCount >= 5 {
            return 1.0
        } else if activityCount >= 3 {
            return 0.66
        } else {
            return 0.33
        }
    }
    
    // Activity ring colors - gradient from light to vibrant blue
    private var ringGradient: LinearGradient {
        if activityProgress >= 1.0 {
            return LinearGradient(
                colors: [Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.0, green: 0.5, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if activityProgress >= 0.66 {
            return LinearGradient(
                colors: [Color(red: 0.5, green: 0.8, blue: 1.0), Color(red: 0.3, green: 0.7, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.7, green: 0.85, blue: 1.0), Color(red: 0.5, green: 0.75, blue: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Background rounded rectangle
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isToday 
                        ? LinearGradient(
                            colors: [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.4, green: 0.5, blue: 0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isToday 
                                ? Color.clear 
                                : Color.white.opacity(0.5),
                            lineWidth: 0.5
                        )
                )
            
            // Activity ring indicator (Apple Fitness style)
            if hasActivity {
                Circle()
                    .trim(from: 0.0, to: activityProgress)
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: activityProgress)
                
                // Background ring (subtle gray)
                Circle()
                    .stroke(
                        Color.gray.opacity(isToday ? 0.2 : 0.15),
                        lineWidth: 2.5
                    )
                    .frame(width: 36, height: 36)
            }
            
            // Day number
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday ? .semibold : (hasActivity ? .medium : .regular), design: .rounded))
                .foregroundColor(
                    isToday 
                        ? .white 
                        : (isCurrentMonth 
                            ? Color(red: 0.15, green: 0.25, blue: 0.35) 
                            : Color.gray.opacity(0.35))
                )
        }
        .frame(width: 44, height: 44)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    NavigationView {
        ActivityCalendarView()
    }
}

