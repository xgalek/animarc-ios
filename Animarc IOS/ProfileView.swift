//
//  ProfileView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import FamilyControls

struct ProfileView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var soundsEnabled = true
    @State private var sessionsToday: [FocusSession] = []
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""
    @State private var isSigningOut = false
    @State private var isLoadingStats = false
    
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
                        Text("Settings")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
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
            
            // Top Navigation Bar
            VStack {
                HStack {
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "#374151"))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            isLoadingStats = true
            sessionsToday = await progressManager.getSessionsToday()
            isLoadingStats = false
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
    NavigationStack {
        ProfileView(navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}
