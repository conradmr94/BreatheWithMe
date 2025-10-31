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
    @State private var showDefaultPictureOptions = false
    @State private var selectedDefaultIcon: String?
    
    // Profile name state
    @State private var userName: String = "Profile"
    @State private var isEditingName = false
    @State private var tempUserName: String = ""
    
    // Default profile picture options
    let defaultIcons = [
        "person.circle.fill",
        "face.smiling.fill",
        "figure.mind.and.body",
        "heart.circle.fill",
        "sun.max.fill",
        "moon.stars.fill",
        "leaf.fill",
        "flame.fill"
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture
                    Menu {
                        Button(action: { showImagePicker = true }) {
                            Label("Choose from Photos", systemImage: "photo.on.rectangle")
                        }
                        
                        Button(action: { showDefaultPictureOptions = true }) {
                            Label("Choose Default Icon", systemImage: "person.crop.circle.badge.checkmark")
                        }
                    } label: {
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
                                Image(systemName: selectedDefaultIcon ?? "person.circle.fill")
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
                        if isEditingName {
                            HStack(spacing: 8) {
                                TextField("Enter your name", text: $tempUserName)
                                    .font(.system(size: 28, weight: .light, design: .default))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 250)
                                
                                Button(action: {
                                    if !tempUserName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        userName = tempUserName
                                        saveUserName(tempUserName)
                                    }
                                    isEditingName = false
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                            }
                        } else {
                            Button(action: {
                                tempUserName = userName
                                isEditingName = true
                            }) {
                                HStack(spacing: 6) {
                                    Text(userName)
                                        .font(.system(size: 34, weight: .light, design: .default))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    
                                    Image(systemName: "pencil.circle")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
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
                loadUserName()
                loadSelectedIcon()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, onImageSelected: { image in
                    saveProfileImage(image)
                })
            }
            .sheet(isPresented: $showDefaultPictureOptions) {
                DefaultIconPicker(
                    selectedIcon: $selectedDefaultIcon,
                    icons: defaultIcons,
                    onSelect: { icon in
                        selectedDefaultIcon = icon
                        profileImage = nil // Clear custom image
                        saveSelectedIcon(icon)
                        showDefaultPictureOptions = false
                    }
                )
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
            // Clear selected icon when custom image is set
            UserDefaults.standard.removeObject(forKey: "selectedDefaultIcon")
        }
    }
    
    // MARK: - Default Icon Persistence
    private func loadSelectedIcon() {
        if let icon = UserDefaults.standard.string(forKey: "selectedDefaultIcon") {
            selectedDefaultIcon = icon
        }
    }
    
    private func saveSelectedIcon(_ icon: String) {
        UserDefaults.standard.set(icon, forKey: "selectedDefaultIcon")
        // Clear custom image when icon is selected
        UserDefaults.standard.removeObject(forKey: "profileImage")
    }
    
    // MARK: - User Name Persistence
    private func loadUserName() {
        if let name = UserDefaults.standard.string(forKey: "userName"), !name.isEmpty {
            userName = name
        }
    }
    
    private func saveUserName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "userName")
    }
}

// MARK: - Default Icon Picker
struct DefaultIconPicker: View {
    @Binding var selectedIcon: String?
    let icons: [String]
    let onSelect: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    let columns = [
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            onSelect(icon)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    .padding()
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == icon ? Color(red: 0.5, green: 0.6, blue: 0.7).opacity(0.2) : Color.clear)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? Color(red: 0.5, green: 0.6, blue: 0.7) : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
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


