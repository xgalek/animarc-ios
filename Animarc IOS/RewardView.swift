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
    @StateObject private var revenueCat = RevenueCatManager.shared
    
    @State private var sessionReward: SessionReward?
    @State private var isProcessing = true
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var processingTimeout: Task<Void, Never>?
    
    // Animation state variables for entrance animations
    @State private var campOpacity: Double = 0.0  // Start with black screen, fade in smoothly
    @State private var durationTextOpacity: Double = 0
    @State private var xpTextOpacity: Double = 0
    @State private var xpScale: CGFloat = 0.8
    @State private var breakdownOpacity: Double = 0
    @State private var breakdownOffset: CGFloat = 20
    @State private var continueButtonOpacity: Double = 0
    @State private var animationsStarted = false
    
    var body: some View {
        ZStack {
            // Black background that matches exit transition - creates seamless flow
            Color.black
                .ignoresSafeArea()
            
            // Animated GIF Background - fades in smoothly from black
            GIFImageView(gifName: "Animation_camp", contentMode: .scaleAspectFill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .opacity(campOpacity)
            
            VStack(spacing: 0) {
                // Top Section - Close button (fades in with background)
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
                    .opacity(campOpacity) // Fade in with camp background
                }
                
                if isProcessing {
                    // Processing happens silently - no visible spinner
                    // The camp background fades in smoothly while processing
                    EmptyView()
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
                        // Session duration - fades in
                        Text("Focused for \(formattedDuration)")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(durationTextOpacity)
                        
                        // XP reward display - fades in with scale pop
                        Text("+\(sessionReward?.xpCalculation.totalXP ?? 0) XP")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(hex: "#22C55E"))
                            .shadow(color: Color(hex: "#22C55E").opacity(0.5), radius: 10, x: 0, y: 0)
                            .opacity(xpTextOpacity)
                            .scaleEffect(xpScale)
                        
                        // XP Breakdown in its own box
                        if let xpCalc = sessionReward?.xpCalculation {
                            VStack(spacing: 16) {
                                // XP Breakdown Box - fades in with slide up
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
                                .opacity(breakdownOpacity)
                                .offset(y: breakdownOffset)
                                
                                // Continue button below the box, right-aligned - fades in
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
                                    .opacity(isProcessing ? 0.5 : continueButtonOpacity)
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
        .onAppear {
            // Start processing immediately in background
            Task {
                await processSessionReward()
            }
            
            // Start smooth fade-in of camp background immediately
            // This creates a seamless transition from the black exit screen
            // Processing happens while the background fades in
            withAnimation(.easeOut(duration: 1.2)) {
                campOpacity = 1.0
            }
        }
        .onChange(of: isProcessing) { _, newValue in
            // Trigger content animations when processing completes and there's no error
            if !newValue && !hasError && !animationsStarted {
                animationsStarted = true
                startContentAnimations()
            }
        }
        .onChange(of: hasError) { _, newValue in
            // Trigger content animations when error state changes (if no error and not processing)
            if !newValue && !isProcessing && !animationsStarted {
                animationsStarted = true
                startContentAnimations()
            }
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
                let isPro = await revenueCat.isPro
                let droppedItem = try await SupabaseManager.shared.dropRandomItem(
                    userId: userId,
                    userRank: progressManager.currentRank,
                    isPro: isPro
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
    
    // MARK: - Animation Functions
    
    private func startContentAnimations() {
        // Content animations start smoothly after camp background has faded in
        // Timing is adjusted to feel more natural and responsive
        
        // 0.3s: "Focused for XX:XX" text fades in (smooth, faster)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                durationTextOpacity = 1.0
            }
        }
        
        // 0.5s: "+XXX XP" text fades in + pops (spring animation for delight)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                xpTextOpacity = 1.0
                xpScale = 1.0
            }
        }
        
        // 0.8s: Breakdown box fades in + slides up (smooth reveal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.5)) {
                breakdownOpacity = 1.0
                breakdownOffset = 0
            }
        }
        
        // 1.0s: Continue button fades in (final element)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                continueButtonOpacity = 1.0
            }
        }
    }
}

#Preview {
    NavigationStack {
        RewardView(sessionDuration: 754, navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}
