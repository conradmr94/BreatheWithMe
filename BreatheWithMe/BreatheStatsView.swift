//
//  BreatheStatsView.swift
//  BreatheWithMe
//

import SwiftUI

struct BreatheStatsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Breathe Stats")
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))

            // Placeholder content; wire to real stats later
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Completed Sessions")
                    Spacer()
                    Text("—")
                }
                HStack {
                    Text("Total Time")
                    Spacer()
                    Text("—")
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
    }
}

#Preview {
    NavigationView { BreatheStatsView() }
}


