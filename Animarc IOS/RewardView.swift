//
//  RewardView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct RewardView: View {
    let sessionDuration: Int  // Duration in seconds
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var progressManager: UserProgressManager
    
    @State private var sessionReward: SessionReward?
    @State private var isProcessing = true
    @State private var showLevelUp = false
    @State private var showRankUp = false
    @State private var droppedItem: PortalItem?
    @State private var isLoadingItem = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Section - Close button
                HStack {
                    Spacer()
                    Button(action: {
                        navigationPath = NavigationPath()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                
                Spacer()
                
                if isProcessing {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Calculating rewards...")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                } else {
                    // Center Content
                    VStack(spacing: 24) {
                        // SESSION COMPLETE! text
                        Text("SESSION COMPLETE!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Session duration
                        Text("Focused for \(formattedDuration)")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        
                        // XP reward display
                        Text("+\(sessionReward?.xpCalculation.totalXP ?? 0) XP")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "#22C55E"))
                            .shadow(color: Color(hex: "#22C55E").opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        // XP Breakdown
                        if let xpCalc = sessionReward?.xpCalculation {
                            VStack(spacing: 8) {
                                ForEach(xpCalc.breakdown, id: \.label) { item in
                                    HStack {
                                        Text(item.label)
                                            .font(.subheadline)
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                        Spacer()
                                        Text("+\(item.amount)")
                                            .font(.subheadline)
                                            .foregroundColor(Color(hex: "#22C55E"))
                                    }
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#243447"))
                            .cornerRadius(12)
                            .padding(.horizontal, 30)
                        }
                        
                        // Level Up indicator
                        if sessionReward?.didLevelUp == true {
                            VStack(spacing: 8) {
                                Text("🎉 LEVEL UP!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "#FFD700"))
                                
                                Text("Level \(sessionReward?.oldLevel ?? 1) → Level \(sessionReward?.newLevel ?? 1)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700").opacity(0.3), Color(hex: "#FF8C00").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 30)
                        }
                        
                        // Rank Up indicator
                        if sessionReward?.didRankUp == true, let newRank = sessionReward?.newRank {
                            VStack(spacing: 8) {
                                Text("⭐ RANK UP!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(newRank.swiftUIColor)
                                
                                Text("\(sessionReward?.oldRank?.code ?? "E")-Rank → \(newRank.code)-Rank")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(newRank.title)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(newRank.swiftUIColor.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal, 30)
                        }
                        
                        // Item Drop indicator
                        if let item = droppedItem {
                            VStack(spacing: 12) {
                                Text("🎁 NEW ITEM UNLOCKED!")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(Color(hex: "#FFD700"))
                                
                                // Rank badge
                                Text("\(item.rolledRank)-RANK")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(item.rankColor)
                                    .cornerRadius(8)
                                
                                AsyncImage(url: URL(string: item.iconUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .tint(.white)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 60, height: 60)
                                    case .failure:
                                        Image(systemName: "gift.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(Color(hex: "#9CA3AF"))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("+\(item.statValue) \(item.statType)")
                                    .font(.subheadline)
                                    .foregroundColor(item.rankColor)
                            }
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD700").opacity(0.2), Color(hex: "#FFA500").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 30)
                        }
                        
                        // Celebratory icon (if no level/rank up/item drop)
                        if sessionReward?.didLevelUp != true && sessionReward?.didRankUp != true && droppedItem == nil {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 60))
                                .foregroundColor(Color(hex: "#FFD700"))
                                .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 10, x: 0, y: 0)
                        }
                    }
                    .padding(.vertical, 40)
                }
                
                Spacer()
                
                // Stats Section
                if !isProcessing {
                    VStack(spacing: 12) {
                        Text("Total XP: \(progressManager.totalXP)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        
                        Text("Current Level: \(progressManager.currentLevel)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .padding(.bottom, 40)
                }
                
                // Bottom Section - CONTINUE button
                Button(action: {
                    navigationPath = NavigationPath()
                }) {
                    Text("CONTINUE")
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
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.5 : 1.0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await processSessionReward()
        }
    }
    
    // MARK: - Helper Functions
    
    private func processSessionReward() async {
        // Convert seconds to minutes (minimum 1 minute for XP)
        let minutes = max(1, sessionDuration / 60)
        
        // Award XP and get result
        sessionReward = await progressManager.awardXP(durationMinutes: minutes)
        
        // Try to drop item (checks eligibility internally)
        isLoadingItem = true
        if let userId = await getCurrentUserId() {
            do {
                droppedItem = try await SupabaseManager.shared.dropRandomItem(
                    userId: userId,
                    userRank: progressManager.currentRank
                )
            } catch {
                print("Failed to drop item: \(error)")
            }
        }
        isLoadingItem = false
        
        isProcessing = false
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.user.id
        } catch {
            print("Failed to get user ID: \(error)")
            return nil
        }
    }
    
    private var formattedDuration: String {
        let minutes = sessionDuration / 60
        let seconds = sessionDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RewardView(sessionDuration: 754, navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}
