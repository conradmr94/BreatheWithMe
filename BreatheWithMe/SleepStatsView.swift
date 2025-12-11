//
//  SleepStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct SleepStatsView: View {
    @AppStorage("sleepStats") private var sleepStatsData: Data = Data()
    
    private var sleepStats: SleepStats {
        if let decoded = try? JSONDecoder().decode(SleepStats.self, from: sleepStatsData) {
            return decoded
        }
        return SleepStats()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
            Text("Sleep Stats")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                .padding(.top, 8)
            
            // Local Sleep Stats (always available)
            VStack(alignment: .leading, spacing: 12) {
                Text("In-App Sleep Sessions")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                
                HStack {
                    Text("Completed Sessions")
                    Spacer()
                    Text("\(sleepStats.sleepSessionsCompleted)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                }
                
                HStack {
                    Text("Total Sleep Time")
                    Spacer()
                    Text(sleepStats.sleepSessionsCompleted > 0 ? sleepStats.totalSleepTimeFormatted : "—")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                }
                
                HStack {
                    Text("Average Session")
                    Spacer()
                    Text(sleepStats.averageSleepTimeFormatted)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                }
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(Color(red: 0.35, green: 0.45, blue: 0.55))
            .frame(maxWidth: 360)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
            )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 8)
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
    NavigationView { SleepStatsView() }
}


