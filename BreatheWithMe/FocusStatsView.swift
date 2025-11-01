//
//  FocusStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct FocusStatsView: View {
    @AppStorage("focusStats") private var focusStatsData: Data = Data()
    @StateObject private var userStatsManager = UserStatsManager()
    
    // Read the same duration settings as FocusView
    @AppStorage("focusDuration") private var focusDuration: Int = 1500 // 25 minutes
    @AppStorage("shortBreakDuration") private var shortBreakDuration: Int = 300 // 5 minutes
    @AppStorage("longBreakDuration") private var longBreakDuration: Int = 900 // 15 minutes
    
    private var focusStats: FocusStats {
        get {
            if let decoded = try? JSONDecoder().decode(FocusStats.self, from: focusStatsData) {
                return decoded
            }
            return FocusStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                focusStatsData = encoded
            }
        }
    }
    
    // Calculate sessions this week
    private var focusSessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        
        return userStatsManager.sessionHistory.filter { session in
            session.activityType == .focus && session.date >= weekStart
        }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Focus Stats")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
                    Text("Your productivity insights")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                }
                .padding(.top, 20)
                
                // Overview Card - Total Sessions & Time
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus Sessions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("\(focusStats.focusSessionsCompleted)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Focus Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text(focusStats.totalFocusTimeFormatted)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
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
                
                // Average Durations
                if focusStats.focusSessionsCompleted > 0 {
                    VStack(spacing: 12) {
                        // Average Focus Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "timer")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
                                
                                Text("Avg Focus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            Text(focusStats.averageFocusDurationFormatted)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.9, green: 0.5, blue: 0.3).opacity(0.08))
                        )
                        
                        // Average Break Durations
                        HStack(spacing: 12) {
                            // Average Short Break
                            if focusStats.shortBreaksCompleted > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "cup.and.saucer.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                                        
                                        Text("Avg Short")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Text(focusStats.averageShortBreakDurationFormatted)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.6, green: 0.8, blue: 0.7).opacity(0.08))
                                )
                            }
                            
                            // Average Long Break
                            if focusStats.longBreaksCompleted > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "pause.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.9))
                                        
                                        Text("Avg Long")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Text(focusStats.averageLongBreakDurationFormatted)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 0.7, green: 0.7, blue: 0.9).opacity(0.08))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Break Types Breakdown
                if focusStats.restSessionsCompleted > 0 {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.5))
                            
                            Text("Break Types")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        HStack(spacing: 16) {
                            // Short Breaks
                            VStack(spacing: 8) {
                                Text("\(focusStats.shortBreaksCompleted)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                                
                                Text("Short Breaks")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                
                                Text("\(shortBreakDuration / 60) min")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.6, green: 0.8, blue: 0.7).opacity(0.1))
                            )
                            
                            // Long Breaks
                            VStack(spacing: 8) {
                                Text("\(focusStats.longBreaksCompleted)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.9))
                                
                                Text("Long Breaks")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                
                                Text("\(longBreakDuration / 60) min")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.7, green: 0.7, blue: 0.9).opacity(0.1))
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
                
                // Total Rest Time Card
                if focusStats.restSessionsCompleted > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "pause.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.5))
                            
                            Text("Total Rest Time")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text(focusStats.totalRestTimeFormatted)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            
                            Text("across \(focusStats.restSessionsCompleted) break\(focusStats.restSessionsCompleted == 1 ? "" : "s")")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
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
                }
                
                // Details Section
                if focusStats.focusSessionsCompleted > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.3))
                                .frame(width: 24)
                            
                            Text("Longest Focus Session")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            
                            Spacer()
                            
                            Text(focusStats.longestFocusSessionSeconds > 0 ? focusStats.longestFocusSessionFormatted : "—")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color(red: 0.5, green: 0.8, blue: 0.5))
                                .frame(width: 24)
                            
                            Text("This Week")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            
                            Spacer()
                            
                            Text("\(focusSessionsThisWeek)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "sum")
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.9))
                                .frame(width: 24)
                            
                            Text("Total Sessions")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            
                            Spacer()
                            
                            Text("\(focusStats.focusSessionsCompleted + focusStats.restSessionsCompleted)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
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
                
                // Empty state
                if focusStats.focusSessionsCompleted == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "timer")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        
                        Text("No Sessions Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        
                        Text("Complete your first focus session\nto see your statistics here")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView { FocusStatsView() }
}


