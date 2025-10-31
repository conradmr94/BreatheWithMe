//
//  SleepStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct SleepStatsView: View {
    @StateObject private var vm = SleepViewModel()
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
            
            // HealthKit Sleep Data Section (always show some card)
            if vm.isAuthorized {
                // Case 1: HealthKit authorized WITH data
                if let lastNight = vm.lastNight {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HealthKit Sleep Data")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        
                        HStack {
                            Text("Last Night Sleep")
                            Spacer()
                            Text(vm.formatHours(lastNight.totalHours))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        HStack {
                            Text("14-Day Average")
                            Spacer()
                            Text(vm.formatHours(vm.rollingAvgHours14))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        HStack {
                            Text("REM Sleep")
                            Spacer()
                            Text(String(format: "%.1fh", lastNight.stageHours(.rem)))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        HStack {
                            Text("Deep Sleep")
                            Spacer()
                            Text(String(format: "%.1fh", lastNight.stageHours(.deep)))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        HStack {
                            Text("Core Sleep")
                            Spacer()
                            Text(String(format: "%.1fh", lastNight.stageHours(.core)))
                                .font(.system(size: 15, weight: .medium))
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
                } else {
                    // Case 2: HealthKit authorized but NO data
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HealthKit Sleep Data")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        
                        VStack(spacing: 8) {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7).opacity(0.5))
                            
                            Text("No Sleep Data Available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            
                            Text("Track your sleep with Apple Watch or iPhone to see detailed sleep analysis here.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
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
            } else {
                // Case 3: HealthKit NOT authorized
                VStack(alignment: .leading, spacing: 12) {
                    Text("HealthKit Sleep Data")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                    
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4).opacity(0.7))
                        
                        Text("HealthKit Not Authorized")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                        
                        Text("Enable HealthKit to see detailed sleep analysis from your Apple Watch or iPhone.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                    .font(.system(size: 14))
                                Text("Open Settings")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.5, green: 0.6, blue: 0.8))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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

                Spacer().frame(height: 40)
            }
            .padding(20)
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
        .onAppear {
            vm.onAppear()
        }
    }
}

#Preview {
    NavigationView { SleepStatsView() }
}


