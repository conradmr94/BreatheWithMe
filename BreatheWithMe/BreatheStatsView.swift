//
//  BreatheStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct BreatheStatsView: View {
    @AppStorage("breatheStats") private var breatheStatsData: Data = Data()
    @StateObject private var userStatsManager = UserStatsManager()
    
    private var breatheStats: BreatheStats {
        get {
            if let decoded = try? JSONDecoder().decode(BreatheStats.self, from: breatheStatsData) {
                return decoded
            }
            return BreatheStats()
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                breatheStatsData = encoded
            }
        }
    }
    
    // Calculate sessions this week
    private var sessionsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        
        return userStatsManager.sessionHistory.filter { session in
            session.activityType == .breathe && session.date >= weekStart
        }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Breathe Stats")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                    
                    Text("Your breathing practice insights")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                }
                .padding(.top, 20)
                
                // Overview Card - Total Sessions & Time
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Sessions")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text("\(breatheStats.sessionsCompleted)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Time")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            Text(breatheStats.totalTimeFormatted)
                                .font(.system(size: 36, weight: .bold))
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
                
                // Average Duration Card
                if breatheStats.sessionsCompleted > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.9))
                            
                            Text("Average Duration")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        HStack(alignment: .firstTextBaseline) {
                            Text(breatheStats.averageDurationFormatted)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            
                            Text("per session")
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
                
                // Session Type Breakdown
                if breatheStats.sessionsCompleted > 0 {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.9))
                            
                            Text("Session Types")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        // 4-7-8 Sessions
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("4-7-8 Technique")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                
                                Text("Inhale 4s • Hold 7s • Exhale 8s")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(breatheStats.sessions478)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.8))
                                
                                if breatheStats.sessionsCompleted > 0 {
                                    Text("\(Int(Double(breatheStats.sessions478) / Double(breatheStats.sessionsCompleted) * 100))%")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.6, green: 0.5, blue: 0.8).opacity(0.08))
                        )
                        
                        // Standard Sessions
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Standard Breathing")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                
                                Text("Custom interval breathing")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(breatheStats.standardSessions)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 0.9))
                                
                                if breatheStats.sessionsCompleted > 0 {
                                    Text("\(Int(Double(breatheStats.standardSessions) / Double(breatheStats.sessionsCompleted) * 100))%")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.4, green: 0.7, blue: 0.9).opacity(0.08))
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                }
                
                // Additional Stats
                if breatheStats.sessionsCompleted > 0 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.5))
                                .frame(width: 24)
                            
                            Text("Longest Session")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            
                            Spacer()
                            
                            Text(breatheStats.longestSessionSeconds > 0 ? breatheStats.longestSessionFormatted : "—")
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
                            
                            Text("\(sessionsThisWeek)")
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
                if breatheStats.sessionsCompleted == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "wind")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        
                        Text("No Sessions Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        
                        Text("Complete your first breathing session\nto see your statistics here")
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
    NavigationView { BreatheStatsView() }
}


