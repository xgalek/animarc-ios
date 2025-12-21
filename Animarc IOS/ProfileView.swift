//
//  ProfileView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
// TEMPORARILY DISABLED: import FamilyControls // Commented out pending Apple's approval

struct ProfileView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    // TEMPORARILY DISABLED: App blocking code commented out pending Apple's approval
    // @StateObject private var appBlockingManager = AppBlockingManager.shared
    @State private var notificationsEnabled = true
    @State private var soundsEnabled = true
    @State private var sessionsToday: [FocusSession] = []
    // TEMPORARILY DISABLED: FamilyActivitySelection state variables commented out
    // @State private var selection = FamilyActivitySelection()
    // @State private var showPicker = false
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var isSigningOut = false
    @State private var isLoadingStats = false
    @AppStorage("KeepScreenOnDuringFocus") private var keepScreenOn: Bool = true
    @State private var isEditingDisplayName = false
    @State private var editedDisplayName = ""
    @State private var isSavingDisplayName = false
    @State private var showDisplayNameError = false
    @State private var displayNameErrorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Top Section - Title
                    HStack {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Middle Section - Quick Stats Grid
                    HStack(spacing: 16) {
                        // Sessions Today
                        StatCard(
                            icon: "flame.fill",
                            label: "Sessions Today",
                            value: isLoadingStats ? "..." : "\(sessionsToday.count)"
                        )
                        
                        // Total Sessions
                        StatCard(
                            icon: "checkmark.circle.fill",
                            label: "Total Sessions",
                            value: "\(progressManager.totalSessions)"
                        )
                        
                        // Total XP
                        StatCard(
                            icon: "star.fill",
                            label: "Total XP",
                            value: "\(progressManager.totalXP)"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Bottom Section - Settings
                    VStack(alignment: .leading, spacing: 20) {
                        // Profile Section
                        Text("Profile")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            // Display Name Row
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                    .frame(width: 24)
                                
                                if isEditingDisplayName {
                                    TextField("Enter your name", text: $editedDisplayName)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled()
                                        .onAppear {
                                            editedDisplayName = progressManager.userProgress?.displayName ?? ""
                                        }
                                } else {
                                    Text(progressManager.userProgress?.displayName ?? "Not set")
                                        .font(.body)
                                        .foregroundColor(progressManager.userProgress?.displayName != nil ? .white : Color(hex: "#9CA3AF"))
                                }
                                
                                Spacer()
                                
                                if isEditingDisplayName {
                                    // Save button
                                    Button(action: {
                                        Task {
                                            await saveDisplayName()
                                        }
                                    }) {
                                        if isSavingDisplayName {
                                            ProgressView()
                                                .tint(.white)
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Save")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color(hex: "#6B46C1"))
                                                .cornerRadius(8)
                                        }
                                    }
                                    .disabled(isSavingDisplayName || editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    
                                    // Cancel button
                                    Button(action: {
                                        isEditingDisplayName = false
                                        editedDisplayName = ""
                                    }) {
                                        Text("Cancel")
                                            .font(.subheadline)
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                    }
                                } else {
                                    // Edit button
                                    Button(action: {
                                        isEditingDisplayName = true
                                        editedDisplayName = progressManager.userProgress?.displayName ?? ""
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#6B46C1"))
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        Text("Settings")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            // Notifications Toggle
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                toggle: $notificationsEnabled
                            )
                            
                            Divider()
                                .background(Color(hex: "#9CA3AF").opacity(0.3))
                                .padding(.leading, 60)
                            
                            // Sounds Toggle
                            SettingsRow(
                                icon: "speaker.wave.2.fill",
                                title: "Sounds",
                                toggle: $soundsEnabled
                            )
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // Focus Settings Section
                        Text("Focus Sessions")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "lock.open.fill",
                                title: "Keep screen on",
                                toggle: $keepScreenOn
                            )
                            
                            // Info text
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                
                                Text("Prevents phone from auto-locking during focus sessions")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#374151").opacity(0.5))
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // TEMPORARILY DISABLED: App Allowlist Section commented out pending Apple's approval
                        /*
                        // App Allowlist Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Allowed Apps")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                // Authorization Status
                                HStack {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(appBlockingManager.isAuthorized ? Color(hex: "#22C55E") : Color(hex: "#DC2626"))
                                        .frame(width: 24)
                                    
                                    Text("Screen Time Permission")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text(appBlockingManager.isAuthorized ? "Authorized" : "Not Authorized")
                                        .font(.subheadline)
                                        .foregroundColor(appBlockingManager.isAuthorized ? Color(hex: "#22C55E") : Color(hex: "#DC2626"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                
                                if !appBlockingManager.isAuthorized {
                                    Divider()
                                        .background(Color(hex: "#9CA3AF").opacity(0.3))
                                        .padding(.leading, 60)
                                    
                                    Button(action: {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "gear")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color(hex: "#6B46C1"))
                                                .frame(width: 24)
                                            
                                            Text("Open Settings")
                                                .font(.body)
                                                .foregroundColor(Color(hex: "#6B46C1"))
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "#9CA3AF"))
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                    }
                                }
                                
                                if appBlockingManager.isAuthorized {
                                    Divider()
                                        .background(Color(hex: "#9CA3AF").opacity(0.3))
                                        .padding(.leading, 60)
                                    
                                    Button(action: {
                                        showPicker = true
                                    }) {
                                        HStack {
                                            Image(systemName: "app.badge")
                                                .font(.system(size: 18))
                                                .foregroundColor(Color(hex: "#9CA3AF"))
                                                .frame(width: 24)
                                            
                                            Text("Select Apps to Allow")
                                                .font(.body)
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            if !appBlockingManager.blockedApplications.isEmpty {
                                                Text("\(appBlockingManager.blockedApplications.count)")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color(hex: "#6B46C1"))
                                                    .cornerRadius(8)
                                            }
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "#9CA3AF"))
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                    }
                                    
                                    // Display selected apps with icons
                                    if !appBlockingManager.selectedActivity.applicationTokens.isEmpty {
                                        Divider()
                                            .background(Color(hex: "#9CA3AF").opacity(0.3))
                                            .padding(.leading, 60)
                                        
                                        HStack {
                                            Text("Allowed during focus:")
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "#9CA3AF"))
                                            
                                            Spacer()
                                            
                                            // Display app icons horizontally
                                            HStack(spacing: 8) {
                                                ForEach(Array(appBlockingManager.selectedActivity.applicationTokens), id: \.self) { token in
                                                    Label(token)
                                                        .labelStyle(.iconOnly)
                                                        .frame(width: 32, height: 32)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                    }
                                    
                                    Divider()
                                        .background(Color(hex: "#9CA3AF").opacity(0.3))
                                        .padding(.leading, 60)
                                    
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                            .frame(width: 24)
                                        
                                        Text("Phone, Messages, and up to 2 apps remain accessible")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                }
                            }
                            .background(Color(hex: "#374151"))
                            .cornerRadius(15)
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                        */
                        
                        // Future buttons placeholder
                        VStack(spacing: 12) {
                            Button(action: {
                                // About action - placeholder
                            }) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                    Text("About")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(15)
                            }
                            
                            Button(action: {
                                // Help action - placeholder
                            }) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                    Text("Help")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(15)
                            }
                            
                            Button(action: {
                                Task {
                                    await handleSignOut()
                                }
                            }) {
                                HStack {
                                    if isSigningOut {
                                        ProgressView()
                                            .tint(.red)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                    }
                                    Text(isSigningOut ? "Signing Out..." : "Sign Out")
                                        .font(.body)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#374151"))
                                .cornerRadius(15)
                            }
                            .disabled(isSigningOut)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            isLoadingStats = true
            sessionsToday = await progressManager.getSessionsToday()
            isLoadingStats = false
            // TEMPORARILY DISABLED: App blocking code commented out pending Apple's approval
            // appBlockingManager.refreshAuthorizationStatus()
        }
        // TEMPORARILY DISABLED: FamilyActivityPicker commented out pending Apple's approval
        /*
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: selection) { _, newSelection in
            // Update selection when user picks apps to allow
            let applicationTokens = newSelection.applicationTokens
            appBlockingManager.setBlockedApplications(applicationTokens, selection: newSelection)
            // Also update local selection for immediate display
            selection = newSelection
        }
        .onAppear {
            // Restore selection from manager when view appears
            selection = appBlockingManager.selectedActivity
        }
        */
        .alert("Sign Out Error", isPresented: $showSignOutError) {
            Button("Retry") {
                Task {
                    await handleSignOut()
                }
            }
            Button("Cancel", role: .cancel) {
                isSigningOut = false
            }
        } message: {
            Text(signOutErrorMessage)
        }
        .alert("Display Name Error", isPresented: $showDisplayNameError) {
            Button("OK", role: .cancel) {
                showDisplayNameError = false
            }
        } message: {
            Text(displayNameErrorMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleSignOut() async {
        isSigningOut = true
        
        do {
            try await SupabaseManager.shared.signOut()
            // Sign out successful - state will be updated by SupabaseManager
            await MainActor.run {
                isSigningOut = false
            }
        } catch {
            await MainActor.run {
                isSigningOut = false
                signOutErrorMessage = "Failed to sign out: \(error.localizedDescription). Please try again."
                showSignOutError = true
            }
            print("ProfileView: Sign out error: \(error)")
        }
    }
    
    private func saveDisplayName() async {
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            await MainActor.run {
                displayNameErrorMessage = "Not authenticated. Please sign in again."
                showDisplayNameError = true
                isEditingDisplayName = false
                isSavingDisplayName = false
            }
            return
        }
        
        let trimmedName = editedDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            await MainActor.run {
                displayNameErrorMessage = "Display name cannot be empty."
                showDisplayNameError = true
                isSavingDisplayName = false
            }
            return
        }
        
        await MainActor.run {
            isSavingDisplayName = true
        }
        
        do {
            let updatedProgress = try await SupabaseManager.shared.updateDisplayName(
                userId: userId,
                newName: trimmedName
            )
            
            await MainActor.run {
                progressManager.userProgress = updatedProgress
                isEditingDisplayName = false
                isSavingDisplayName = false
                editedDisplayName = ""
                
                // Haptic feedback for success
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch {
            await MainActor.run {
                isSavingDisplayName = false
                displayNameErrorMessage = "Failed to save display name: \(error.localizedDescription). Please try again."
                showDisplayNameError = true
            }
            print("ProfileView: Display name update error: \(error)")
        }
    }
}

// Stat Card Component
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "#A770FF"))
            
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "#9CA3AF"))
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(hex: "#374151"))
        .cornerRadius(15)
    }
}

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    @Binding var toggle: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $toggle)
                .labelsHidden()
                .tint(Color(hex: "#6B46C1"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProgressManager.shared)
}
