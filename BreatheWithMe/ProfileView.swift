//
//  ProfileView.swift
//  BreatheWithMe
//

import SwiftUI

struct ProfileView: View {
    var onDismiss: (() -> Void)? = nil
    @StateObject private var statsManager = UserStatsManager()
    
    // Profile picture state
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture
                    Button(action: { showImagePicker = true }) {
                        ZStack(alignment: .bottomTrailing) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(red: 0.5, green: 0.6, blue: 0.7), lineWidth: 3)
                                    )
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            // Camera icon indicator
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.5, green: 0.6, blue: 0.7))
                                        .frame(width: 36, height: 36)
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    VStack(spacing: 8) {
                        Text("Profile")
                            .font(.system(size: 34, weight: .light, design: .default))
                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        
                        Text(statsManager.motivationalMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                    }

                    // Main Stats Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Current Streak", systemImage: "flame.fill")
                                .font(.system(size: 17, weight: .regular))
                            Spacer()
                            Text(statsManager.currentStreak == 0 ? "—" : "\(statsManager.currentStreak) \(statsManager.currentStreak == 1 ? "day" : "days")")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(statsManager.currentStreak >= 3 ? Color.orange : Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("Total Sessions", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .regular))
                            Spacer()
                            Text("\(statsManager.totalSessions)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("Total Time", systemImage: "clock.fill")
                                .font(.system(size: 17, weight: .regular))
                            Spacer()
                            Text(statsManager.totalSessions > 0 ? statsManager.totalTimeFormatted : "—")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("Favorite Activity", systemImage: "star.fill")
                                .font(.system(size: 17, weight: .regular))
                            Spacer()
                            Text(statsManager.favoriteActivity)
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
                    
                    // Additional Stats Card
                    if statsManager.totalSessions > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("More Stats")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            
                            HStack {
                                Text("Active Days")
                                Spacer()
                                Text("\(statsManager.totalActiveDays)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                            
                            HStack {
                                Text("Longest Streak")
                                Spacer()
                                Text("\(statsManager.longestStreak) \(statsManager.longestStreak == 1 ? "day" : "days")")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                            
                            HStack {
                                Text("Avg. Session")
                                Spacer()
                                Text(statsManager.averageSessionDurationFormatted)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                            
                            HStack {
                                Text("This Week")
                                Spacer()
                                Text("\(statsManager.sessionsThisWeek) sessions")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                            }
                        }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        .frame(maxWidth: 360)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                        )
                    }

                    // Bottom stats shortcuts
                    VStack(spacing: 10) {
                        Text("Detailed Stats")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                            .frame(maxWidth: 360, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            NavigationLink(destination: BreatheStatsView()) {
                                HStack {
                                    Label("Breathe Stats", systemImage: "wind")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.65, green: 0.8, blue: 0.92))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.65, green: 0.8, blue: 0.92).opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(destination: FocusStatsView()) {
                                HStack {
                                    Label("Focus Stats", systemImage: "timer")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.6, green: 0.8, blue: 0.7).opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())

                            NavigationLink(destination: SleepStatsView()) {
                                HStack {
                                    Label("Sleep Stats", systemImage: "moon.stars.fill")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.8).opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(maxWidth: 360)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                loadProfileImage()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, onImageSelected: { image in
                    saveProfileImage(image)
                })
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
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let t = value.translation
                        // Require a larger upward swipe (180) and stricter horizontal tolerance (50)
                        // to prevent accidental dismissal while scrolling
                        if t.height < -180 && abs(t.width) < 50 {
                            onDismiss?()
                        }
                    }
            )
        }
    }
    
    // MARK: - Profile Image Persistence
    private func loadProfileImage() {
        if let imageData = UserDefaults.standard.data(forKey: "profileImage"),
           let uiImage = UIImage(data: imageData) {
            profileImage = uiImage
        }
    }
    
    private func saveProfileImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "profileImage")
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageSelected(uiImage)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfileView()
}


