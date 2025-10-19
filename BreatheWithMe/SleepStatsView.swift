//
//  SleepStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct SleepStatsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Sleep Stats")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total Sleep Time")
                    Spacer()
                    Text("—")
                }
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.white.opacity(0.8))
            .frame(maxWidth: 360)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.12))
                    .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
            )

            Spacer()
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView { SleepStatsView() }
}


