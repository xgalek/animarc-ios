//
//  RewardView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import UIKit

struct RewardView: View {
    let sessionDuration: Int  // Duration in seconds
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var progressManager: UserProgressManager
    
    @State private var sessionReward: SessionReward?
    @State private var isProcessing = true
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var processingTimeout: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Animated GIF Background
            GIFImageView(gifName: "Animation_camp", contentMode: .scaleAspectFill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
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
                
                if isProcessing {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Calculating rewards...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                } else if hasError {
                    // Error state
                    VStack(spacing: 24) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#DC2626"))
                        
                        Text("Failed to Process Rewards")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                Task {
                                    await retryProcessing()
                                }
                            }) {
                                Text("Retry")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(hex: "#6B46C1"))
                                    .cornerRadius(25)
                            }
                            
                            Button(action: {
                                navigationPath = NavigationPath()
                            }) {
                                Text("Continue Anyway")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                    }
                    .padding(.top, 60)
                } else {
                    // Top Content
                    VStack(spacing: 24) {
                        // Session duration
                        Text("Focused for \(formattedDuration)")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        // XP reward display
                        Text("+\(sessionReward?.xpCalculation.totalXP ?? 0) XP")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "#22C55E"))
                            .shadow(color: Color(hex: "#22C55E").opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        // XP Breakdown in its own box
                        if let xpCalc = sessionReward?.xpCalculation {
                            VStack(spacing: 16) {
                                // XP Breakdown Box
                                VStack(spacing: 12) {
                                    ForEach(xpCalc.breakdown, id: \.label) { item in
                                        HStack {
                                            Text(item.label)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                            Spacer()
                                            Text("+\(item.amount)")
                                                .font(.subheadline)
                                                .foregroundColor(Color(hex: "#22C55E"))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                                
                                // Continue button below the box, right-aligned
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        navigationPath = NavigationPath()
                                    }) {
                                        Text("CONTINUE")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                            .background(Color(hex: "#6B46C1"))
                                            .cornerRadius(15)
                                    }
                                    .disabled(isProcessing)
                                    .opacity(isProcessing ? 0.5 : 1.0)
                                }
                            }
                            .padding(.horizontal, 30)
                        }
                        
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 30)
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await processSessionReward()
        }
    }
    
    // MARK: - Helper Functions
    
    private func processSessionReward() async {
        // Set timeout (10 seconds)
        processingTimeout = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if !Task.isCancelled && isProcessing {
                await MainActor.run {
                    hasError = true
                    errorMessage = "Processing is taking longer than expected. Please check your connection and try again."
                    isProcessing = false
                }
            }
        }
        
        // Convert seconds to minutes (minimum 1 minute for XP)
        let minutes = max(1, sessionDuration / 60)
        
        // Award XP and get result (this will store pending level/rank up in progressManager)
        sessionReward = await progressManager.awardXP(durationMinutes: minutes)
        
        // Check if XP award failed
        if sessionReward == nil {
            processingTimeout?.cancel()
            await MainActor.run {
                hasError = true
                errorMessage = progressManager.errorMessage ?? "Failed to award XP. Your session was recorded but rewards couldn't be processed."
                isProcessing = false
            }
            return
        }
        
        // Try to drop item (checks eligibility internally) - non-critical
        if let userId = await getCurrentUserId() {
            do {
                let droppedItem = try await SupabaseManager.shared.dropRandomItem(
                    userId: userId,
                    userRank: progressManager.currentRank
                )
                // Store in progressManager for celebration on HomeView
                progressManager.pendingItemDrop = droppedItem
            } catch {
                print("Failed to drop item: \(error)")
                // Non-critical error, don't show to user
            }
        }
        
        processingTimeout?.cancel()
        isProcessing = false
    }
    
    private func retryProcessing() async {
        hasError = false
        errorMessage = ""
        isProcessing = true
        await processSessionReward()
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
