//
//  HomeView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false
    @State private var showLevelUpModal = false
    @State private var showItemDropModal = false
    @State private var showPermissionModal = false
    @State private var showPermissionDeniedAlert = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Top Status Bar
                HStack {
                    // Fire emoji and streak number
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 20))
                        Text("\(progressManager.currentStreak)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Stats text with different colors
                    HStack(spacing: 4) {
                        Text("\(progressManager.currentRank)-Rank")
                            .font(.headline)
                            .foregroundColor(progressManager.currentRankInfo.swiftUIColor)
                        Text("|")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Text("LVL \(progressManager.currentLevel)")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#A770FF"))
                        Text("|")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Text("\(progressManager.totalXP) xp")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#22C55E"))
                    }
                    
                    Spacer()
                    
                    // Avatar button
                    AvatarButton(showProfile: $showProfile)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Center Content
                VStack(spacing: 16) {
                    // Motivational quote
                    Text("Success is nothing more than a few simple disciplines, practiced every day.")
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    // Attribution
                    Text("-Jim Rohn")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
                .padding(.vertical, 20)
                
                // Portal Image
                GIFImageView(gifName: "Green portal")
                    .frame(width: 200, height: 200)
                    .shadow(color: Color(hex: "#7FFF00").opacity(0.5), radius: 20, x: 0, y: 0)
                    .padding(.top, 30)
                    .padding(.bottom, 40)
                
                // Focus Button
                Button(action: {
                    handleFocusButtonTap()
                }) {
                    Text("FOCUS")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#6B46C1"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                        .shadow(color: Color(hex: "#4A90E2").opacity(0.4), radius: 25, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .disabled(isRequestingPermission)
                
                Spacer()
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "FocusSession" {
                    FocusSessionView(navigationPath: $navigationPath)
                        .environmentObject(progressManager)
                } else if destination.hasPrefix("Reward-") {
                    let durationStr = destination.replacingOccurrences(of: "Reward-", with: "")
                    let duration = Int(durationStr) ?? 0
                    RewardView(sessionDuration: duration, navigationPath: $navigationPath)
                        .environmentObject(progressManager)
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView(navigationPath: .constant(NavigationPath()))
                        .environmentObject(progressManager)
                }
            }
            .onAppear {
                // Check for pending rewards when view appears (including when returning from RewardView)
                checkAndShowPendingRewards()
                // Refresh authorization status
                appBlockingManager.refreshAuthorizationStatus()
            }
            .sheet(isPresented: $showPermissionModal) {
                AppBlockingPermissionModal(
                    isRequestingPermission: $isRequestingPermission,
                    onPermissionGranted: {
                        showPermissionModal = false
                        navigationPath.append("FocusSession")
                    },
                    onPermissionDenied: {
                        showPermissionModal = false
                        showPermissionDeniedAlert = true
                    }
                )
            }
            .alert("Permission Required", isPresented: $showPermissionDeniedAlert) {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Focus sessions require app blocking permission. Please grant Screen Time permission in Settings to continue.")
            }
            .sheet(isPresented: $showLevelUpModal) {
                LevelUpModalView(
                    oldLevel: progressManager.pendingLevelUp?.oldLevel ?? 1,
                    newLevel: progressManager.pendingLevelUp?.newLevel ?? 1,
                    rankUp: progressManager.pendingRankUp
                ) {
                    // On dismiss, clear level up and check for item drop
                    progressManager.pendingLevelUp = nil
                    progressManager.pendingRankUp = nil
                    showLevelUpModal = false
                    
                    // Check for item drop after level up modal closes
                    if progressManager.pendingItemDrop != nil {
                        showItemDropModal = true
                    }
                }
            }
            .sheet(isPresented: $showItemDropModal) {
                if let item = progressManager.pendingItemDrop {
                    ItemDropModalView(item: item) {
                        // On dismiss, clear item drop
                        progressManager.pendingItemDrop = nil
                        showItemDropModal = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleFocusButtonTap() {
        // Check if permission has been requested
        if !appBlockingManager.hasRequestedPermission {
            // First time - show permission modal
            showPermissionModal = true
            return
        }
        
        // Check current authorization status
        appBlockingManager.refreshAuthorizationStatus()
        
        if appBlockingManager.isAuthorized {
            // Permission granted - proceed to focus session
            navigationPath.append("FocusSession")
        } else {
            // Permission denied or revoked - show alert
            showPermissionDeniedAlert = true
        }
    }
    
    private func checkAndShowPendingRewards() {
        // First check for level up
        if progressManager.pendingLevelUp != nil {
            showLevelUpModal = true
            return
        }
        
        // If no level up, check for item drop
        if progressManager.pendingItemDrop != nil {
            showItemDropModal = true
        }
    }
}

// MARK: - Level Up Modal

struct LevelUpModalView: View {
    let oldLevel: Int
    let newLevel: Int
    let rankUp: (oldRank: RankInfo, newRank: RankInfo)?
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#6B46C1").opacity(0.95),
                    Color(hex: "#FFD700").opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("LEVEL UP! 🎉")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Level display
                VStack(spacing: 8) {
                    Text("Level \(oldLevel)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("Level \(newLevel)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "#FFD700"))
                }
                
                // Rank Up indicator (if applicable)
                if let rankUp = rankUp {
                    VStack(spacing: 8) {
                        Text("⭐ RANK UP!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(rankUp.newRank.swiftUIColor)
                        
                        Text("\(rankUp.oldRank.code)-Rank → \(rankUp.newRank.code)-Rank")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(rankUp.newRank.title)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(rankUp.newRank.swiftUIColor.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#6B46C1"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Item Drop Modal

struct ItemDropModalView: View {
    let item: PortalItem
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#FFD700").opacity(0.95),
                    Color(hex: "#FFA500").opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("NEW ITEM! 🎁")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Rank badge
                Text("\(item.rolledRank)-RANK")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(item.rankColor)
                    .cornerRadius(10)
                
                // Item icon
                AsyncImage(url: URL(string: item.iconUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .shadow(color: item.rankColor.opacity(0.5), radius: 15, x: 0, y: 0)
                    case .failure:
                        Image(systemName: "gift.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.8))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Item name
                Text(item.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Stat bonus
                Text("+\(item.statValue) \(item.statType)")
                    .font(.headline)
                    .foregroundColor(item.rankColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Collect")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FFA500"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#FFA500").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
            .padding(.top, 90)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - App Blocking Permission Modal

struct AppBlockingPermissionModal: View {
    @Binding var isRequestingPermission: Bool
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#6B46C1"))
                    .padding(.top, 40)
                
                // Title
                Text("Enter Focus Mode!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Block distracting apps automatically")
                            .font(.body)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .multilineTextAlignment(.center)
                        
                        Text("during focus sessions.")
                            .font(.body)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Maximum focus. No interruptions.")
                        .font(.body)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        requestPermission()
                    }) {
                        Text("Block Apps")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#6B46C1"))
                            .cornerRadius(25)
                            .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                    }
                    .disabled(isRequestingPermission)
                    
                    Button(action: {
                        onPermissionDenied()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .disabled(isRequestingPermission)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            do {
                try await AppBlockingManager.shared.requestAuthorization()
                await MainActor.run {
                    isRequestingPermission = false
                    if AppBlockingManager.shared.isAuthorized {
                        onPermissionGranted()
                    } else {
                        onPermissionDenied()
                    }
                }
            } catch {
                await MainActor.run {
                    isRequestingPermission = false
                    onPermissionDenied()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserProgressManager.shared)
}
