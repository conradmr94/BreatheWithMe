//
//  ProfileView.swift
//  BreatheWithMe
//

import SwiftUI

struct ProfileView: View {
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))

                Text("Profile")
                    .font(.system(size: 34, weight: .light, design: .default))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Streak")
                        Spacer()
                        Text("—")
                    }
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("—")
                    }
                    HStack {
                        Text("Preferences")
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

                // Bottom stats shortcuts
                HStack(spacing: 12) {
                    NavigationLink(destination: BreatheStatsView()) {
                        Label("Breathe Stats", systemImage: "wind")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.65, green: 0.8, blue: 0.92))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    NavigationLink(destination: FocusStatsView()) {
                        Label("Focus Stats", systemImage: "timer")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    NavigationLink(destination: SleepStatsView()) {
                        Label("Sleep Stats", systemImage: "moon.stars.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: 360)

                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onDismiss?() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let t = value.translation
                        if t.height < -100 && abs(t.width) < 80 {
                            onDismiss?()
                        }
                    }
            )
        }
    }
}

#Preview {
    ProfileView()
}


