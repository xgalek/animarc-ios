//
//  HomeView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false
    @State private var showLevelUpModal = false
    @State private var showItemDropModal = false
    
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
                    navigationPath.append("FocusSession")
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
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    HomeView()
        .environmentObject(UserProgressManager.shared)
}
