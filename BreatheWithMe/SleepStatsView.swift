//
//  SleepStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct SleepStatsView: View {
    @StateObject private var vm = SleepViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sleep Stats")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))

            if vm.isAuthorized {
                if let lastNight = vm.lastNight {
                    VStack(alignment: .leading, spacing: 12) {
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
                        HStack {
                            Text("REM Sleep")
                            Spacer()
                            Text(String(format: "%.1fh", lastNight.stageHours(.rem)))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        HStack {
                            Text("Deep Sleep")
                            Spacer()
                            Text(String(format: "%.1fh", lastNight.stageHours(.deep)))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        HStack {
                            Text("Core Sleep")
                            Spacer()
                            Text(String(format: "%.1fh", lastNight.stageHours(.core)))
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
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sleep Data")
                            Spacer()
                            Text("No Data")
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
            } else if let error = vm.lastError {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("HealthKit Error")
                        Spacer()
                        Text("Failed")
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
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Loading Sleep Data")
                        Spacer()
                        Text("...")
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

            Spacer()
        }
        .padding(20)
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


