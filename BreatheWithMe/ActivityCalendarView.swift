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
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Streak")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("\(statsManager.currentStreak)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(statsManager.currentStreak >= 3 ? Color.orange : Color(red: 0.2, green: 0.3, blue: 0.4))
                            Text(statsManager.currentStreak == 1 ? "day" : "days")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Longest Streak")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("\(statsManager.longestStreak)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            Text(statsManager.longestStreak == 1 ? "day" : "days")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    )
                }
                .padding(.horizontal, 20)
                
                // Month selector
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            .padding(10)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer()
                    
                    Text(monthYearString)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(canGoToNextMonth ? Color(red: 0.5, green: 0.6, blue: 0.7) : Color.gray.opacity(0.3))
                            .padding(10)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canGoToNextMonth)
                }
                .padding(.horizontal, 20)
                
                // Calendar grid
                VStack(spacing: 0) {
                    // Days of week header
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 12)
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
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
                                    .frame(height: 50)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
                
                // Activity legend
                VStack(alignment: .leading, spacing: 12) {
                    Text("Activity Legend")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                    
                    HStack(spacing: 20) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.3))
                                .frame(width: 24, height: 24)
                            Text("1-2 sessions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        }
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.6))
                                .frame(width: 24, height: 24)
                            Text("3-4 sessions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(red: 0.65, green: 0.8, blue: 0.92))
                            .frame(width: 24, height: 24)
                        Text("5+ sessions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
                
                // Stats summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("This Month")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                    
                    HStack {
                        Text("Active Days")
                        Spacer()
                        Text("\(activeDaysThisMonth)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                    
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(sessionsThisMonth)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    }
                }
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
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
                    VStack(spacing: 8) {
                        Text(formatDate(date))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        
                        if calendar.isDateInToday(date) {
                            Text("Today")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.5, green: 0.6, blue: 0.7).opacity(0.1))
                                )
                        }
                    }
                    .padding(.top, 20)
                    
                    // Summary card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Sessions")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                Text("\(sessionsForDay.count)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total Time")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                Text(formatTime(seconds: totalTimeSeconds))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    // Activity breakdown
                    if !sessionsByType.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activity Breakdown")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            
                            ForEach(sessionsByType, id: \.type) { item in
                                HStack {
                                    Image(systemName: iconForActivity(item.type))
                                        .font(.system(size: 20))
                                        .foregroundColor(colorForActivity(item.type))
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.type.rawValue)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                        Text("\(item.count) session\(item.count == 1 ? "" : "s")")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatTime(seconds: item.time))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorForActivity(item.type).opacity(0.08))
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Individual sessions
                    if !sessionsForDay.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Session History")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            
                            ForEach(sessionsForDay) { session in
                                HStack {
                                    Image(systemName: iconForActivity(session.activityType))
                                        .font(.system(size: 18))
                                        .foregroundColor(colorForActivity(session.activityType))
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.activityType.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                        Text(formatSessionTime(session.date))
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatTime(seconds: session.durationSeconds))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.95, green: 0.97, blue: 1.0))
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 20)
                    } else {
                        // No activity message
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            
                            Text("No Activity")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            
                            Text("No sessions recorded on this day")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
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
    
    private func formatSessionTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
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
    
    private var activityColor: Color {
        if !hasActivity {
            return Color.clear
        }
        
        if activityCount >= 5 {
            return Color(red: 0.65, green: 0.8, blue: 0.92)
        } else if activityCount >= 3 {
            return Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.6)
        } else {
            return Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.3)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : (isCurrentMonth ? Color(red: 0.2, green: 0.3, blue: 0.4) : Color.gray.opacity(0.4)))
            
            if hasActivity {
                Circle()
                    .fill(activityColor)
                    .frame(width: 6, height: 6)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            Circle()
                .fill(isToday ? Color(red: 0.5, green: 0.6, blue: 0.7) : Color.clear)
                .padding(4)
        )
    }
}

#Preview {
    NavigationView {
        ActivityCalendarView()
    }
}

