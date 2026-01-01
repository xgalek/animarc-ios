//
//  ProfileView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import FamilyControls

struct ProfileView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @StateObject private var revenueCat = RevenueCatManager.shared
    @State private var notificationsEnabled = true
    @State private var soundsEnabled = true
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var isSigningOut = false
    @AppStorage("KeepScreenOnDuringFocus") private var keepScreenOn: Bool = true
    @State private var isEditingDisplayName = false
    @State private var editedDisplayName = ""
    @State private var isSavingDisplayName = false
    @State private var showDisplayNameError = false
    @State private var displayNameErrorMessage = ""
    @State private var showCustomerCenter = false
    @State private var showPaywall = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountError = false
    @State private var deleteAccountErrorMessage = ""
    @State private var isDeletingAccount = false
    
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
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(Color(hex: "#FF9500"))
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
                        
                        // Subscription Section
                        Text("Subscription")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            if revenueCat.isPro {
                                // Pro user - show subscription status (non-clickable)
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#FFD700"))
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Animarc Pro")
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Text("Active")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "#4ADE80"))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                
                                Divider()
                                    .background(Color(hex: "#9CA3AF").opacity(0.3))
                                    .padding(.leading, 60)
                                
                                // Direct Manage Subscription button (Apple requirement)
                                Button(action: {
                                    revenueCat.presentCustomerCenter()
                                }) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                            .frame(width: 24)
                                        
                                        Text("Manage Subscription")
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                }
                            } else {
                                // Free user - show upgrade option
                                Button(action: {
                                    showPaywall = true
                                }) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                            .frame(width: 24)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Upgrade to Pro")
                                                .font(.body)
                                                .foregroundColor(.white)
                                            
                                            Text("Unlock premium features")
                                                .font(.caption)
                                                .foregroundColor(Color(hex: "#9CA3AF"))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider()
                                    .background(Color(hex: "#9CA3AF").opacity(0.3))
                                    .padding(.leading, 60)
                                
                                Button(action: {
                                    showCustomerCenter = true
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                            .frame(width: 24)
                                        
                                        Text("Restore Purchases")
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                }
                            }
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Testing Section (for development)
                        #if DEBUG
                        Text("Testing")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                showPaywall = true
                            }) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#FF9500"))
                                        .frame(width: 24)
                                    
                                    Text("Test Subscription")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        #endif
                        
                        // Sign Out Button
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
                        .disabled(isSigningOut || isDeletingAccount)
                        .padding(.horizontal, 20)
                        
                        // Legal Section
                        Text("Legal")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                openURL("https://animarc.app/privacy")
                            }) {
                                HStack {
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                        .frame(width: 24)
                                    
                                    Text("Privacy Policy")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                            
                            Divider()
                                .background(Color(hex: "#9CA3AF").opacity(0.3))
                                .padding(.leading, 60)
                            
                            Button(action: {
                                openURL("https://animarc.app/terms")
                            }) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                        .frame(width: 24)
                                    
                                    Text("Terms of Use")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Delete Section
                        Text("Delete")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                showDeleteAccountConfirmation = true
                            }) {
                                HStack {
                                    if isDeletingAccount {
                                        ProgressView()
                                            .tint(.red)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                            .frame(width: 24)
                                    }
                                    Text(isDeletingAccount ? "Deleting Account..." : "Delete Account")
                                        .font(.body)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            appBlockingManager.refreshAuthorizationStatus()
        }
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
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteAccountConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                Task {
                    await handleDeleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {
                showDeleteAccountConfirmation = false
            }
        } message: {
            Text("This action cannot be undone. All your data including progress, sessions, items, and streaks will be permanently deleted. Are you sure you want to delete your account?")
        }
        .alert("Delete Account Error", isPresented: $showDeleteAccountError) {
            Button("OK", role: .cancel) {
                showDeleteAccountError = false
                isDeletingAccount = false
            }
        } message: {
            Text(deleteAccountErrorMessage)
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Helper Methods
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
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
    
    private func handleDeleteAccount() async {
        await MainActor.run {
            isDeletingAccount = true
        }
        
        do {
            // Get current user ID
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                await MainActor.run {
                    deleteAccountErrorMessage = "Not authenticated. Please sign in again."
                    showDeleteAccountError = true
                    isDeletingAccount = false
                }
                return
            }
            
            // Delete all user data
            try await SupabaseManager.shared.deleteUserAccount(userId: userId)
            
            // Logout from RevenueCat
            try? await revenueCat.logout()
            
            // Sign out from Supabase (this revokes access)
            try await SupabaseManager.shared.signOut()
            
            // Clear local data
            await MainActor.run {
                progressManager.clearData()
                isDeletingAccount = false
                // User will be redirected to auth screen automatically via SupabaseManager state
            }
            
            print("Account deleted successfully")
        } catch {
            await MainActor.run {
                isDeletingAccount = false
                deleteAccountErrorMessage = "Failed to delete account: \(error.localizedDescription). Please try again or contact support."
                showDeleteAccountError = true
            }
            print("ProfileView: Delete account error: \(error)")
        }
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
                .tint(Color(hex: "#FF9500"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProgressManager.shared)
}
