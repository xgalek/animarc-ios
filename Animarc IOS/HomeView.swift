//
//  HomeView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import FamilyControls

struct HomeView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @StateObject private var errorManager = ErrorManager.shared
    @StateObject private var quoteManager = QuoteManager.shared
    @StateObject private var revenueCat = RevenueCatManager.shared
    @State private var navigationPath = NavigationPath()
    @State private var showLevelUpModal = false
    @State private var showRankUpModal = false
    @State private var showItemDropModal = false
    @State private var showStreakCelebration = false
    @State private var showPermissionModal = false
    @State private var showPermissionDeniedAlert = false
    @State private var isRequestingPermission = false
    @State private var showFocusConfig = false
    @State private var isRefreshing = false
    @State private var currentQuote = ""
    @State private var contentAppeared = false
    @State private var pendingNavigation: String? = nil
    @State private var showPaywall = false
    
    // Portal transition binding - controlled by MainTabView
    @Binding var showPortalTransition: Bool
    let onPortalTransitionComplete: (@escaping () -> Void) -> Void
    
    private let streakCelebrationKey = "lastStreakCelebrationShownDate"
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Persistent error banner if errorMessage is set
                        if let errorMsg = progressManager.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(errorMsg)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    Task {
                                        isRefreshing = true
                                        await progressManager.loadProgress()
                                        isRefreshing = false
                                    }
                                }) {
                                    Text("Retry")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#DC2626"))
                            .padding(.top, 8)
                        }
                        
                        // Top Status Bar
                        HStack(spacing: 8) {
                            // Fire emoji and streak number (tappable to show celebration)
                            Button(action: {
                                if !progressManager.isLoading {
                                    showStreakCelebrationManually()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("🔥")
                                        .font(.system(size: 20))
                                    if progressManager.isLoading {
                                        Text("0")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .shimmer()
                                    } else {
                                        Text("\(progressManager.currentStreak)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(progressManager.isLoading)
                            
                            // XP Progress Bar - animated with micro-interactions
                            AnimatedXPProgressBar(
                                levelProgress: progressManager.levelProgress,
                                isLoading: progressManager.isLoading,
                                previousXP: progressManager.previousTotalXP,
                                previousLevel: progressManager.previousLevel,
                                shouldAnimate: progressManager.shouldAnimateXPChange
                            )
                            .frame(height: 24)
                            
                            // Rank badge - minimalistic
                            if progressManager.isLoading {
                                Text("E-Rank")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 5)
                                    .frame(height: 24)
                                    .background(Color(hex: "#4A90A4"))
                                    .cornerRadius(8)
                                    .shimmer()
                            } else {
                                Text("\(progressManager.currentRank)-Rank")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 5)
                                    .frame(height: 24)
                                    .background(progressManager.currentRankInfo.swiftUIColor)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : -30)
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: contentAppeared)
                        .animation(.easeInOut(duration: 0.3), value: progressManager.isLoading)
                
                Spacer()
                
                // Center Content - Vertically Centered
                VStack(spacing: 0) {
                    // Motivational quote
                    Text(currentQuote)
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 60)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 20)
                        .animation(.easeOut(duration: 1.4), value: contentAppeared)
                    
                    // Portal Image
                    GIFImageView(gifName: "Green portal")
                        .frame(width: 200, height: 200)
                        .shadow(color: Color(hex: "#7FFF00").opacity(0.5), radius: 20, x: 0, y: 0)
                        .padding(.bottom, 70)
                        .opacity(contentAppeared ? 1 : 0)
                        .scaleEffect(contentAppeared ? 1 : 0.7)
                        .animation(.spring(response: 1.2, dampingFraction: 0.7), value: contentAppeared)
                    
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
                    .padding(.bottom, 50)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 30)
                    .animation(.easeOut(duration: 0.6), value: contentAppeared)
                    .disabled(isRequestingPermission)
                }
                .padding(.top, 100)
                
                Spacer()
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .toast(errorManager: errorManager)
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
            .onAppear {
                // Load current quote
                currentQuote = quoteManager.getCurrentQuote()
                
                // Trigger smooth fade-in animation for all elements
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    contentAppeared = true
                }
                
                // Check for pending rewards when view appears (including when returning from RewardView)
                checkAndShowPendingRewards()
                // Check for streak celebration (after rewards)
                checkAndShowStreakCelebration()
                // Refresh authorization status
                appBlockingManager.refreshAuthorizationStatus()
            }
            .sheet(isPresented: $showPermissionModal) {
                AppBlockingPermissionModal(
                    isRequestingPermission: $isRequestingPermission,
                    onPermissionGranted: {
                        showPermissionModal = false
                        showFocusConfig = true
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
                    rankUp: nil
                ) {
                    // On dismiss, clear level up
                    progressManager.pendingLevelUp = nil
                    showLevelUpModal = false
                    
                    // If there's a rank up, show it next
                    if progressManager.pendingRankUp != nil {
                        showRankUpModal = true
                    } else {
                        // Otherwise check for item drop
                        if progressManager.pendingItemDrop != nil {
                            showItemDropModal = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showRankUpModal) {
                if let rankUp = progressManager.pendingRankUp {
                    RankUpModalView(
                        oldRank: rankUp.oldRank,
                        newRank: rankUp.newRank
                    ) {
                        // On dismiss, clear rank up
                        progressManager.pendingRankUp = nil
                        showRankUpModal = false
                        
                        // Check for item drop after rank up modal closes
                        if progressManager.pendingItemDrop != nil {
                            showItemDropModal = true
                        }
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
            .sheet(isPresented: $showStreakCelebration) {
                StreakCelebrationModalView(
                    streakCount: progressManager.currentStreak
                ) {
                    showStreakCelebration = false
                }
            }
            .sheet(isPresented: $showFocusConfig) {
                FocusConfigurationModal(
                    navigationPath: $navigationPath,
                    showPortalTransition: $showPortalTransition,
                    pendingNavigation: $pendingNavigation,
                    onPortalTransitionComplete: onPortalTransitionComplete
                )
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
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
            // Permission granted - show configuration modal first
            showFocusConfig = true
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
        
        // Then check for rank up (if no level up)
        if progressManager.pendingRankUp != nil {
            showRankUpModal = true
            return
        }
        
        // If no level up or rank up, check for item drop
        if progressManager.pendingItemDrop != nil {
            showItemDropModal = true
        }
    }
    
    private func shouldShowStreakCelebration() -> Bool {
        // Don't show if data is still loading
        if progressManager.isLoading {
            return false
        }
        
        // Don't show if streak is 0
        if progressManager.currentStreak <= 0 {
            return false
        }
        
        // Check if already shown today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use date formatter for day-level comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        let todayString = dateFormatter.string(from: today)
        
        if let lastShownDateString = UserDefaults.standard.string(forKey: streakCelebrationKey),
           lastShownDateString == todayString {
            return false // Already shown today
        }
        
        return true
    }
    
    private func checkAndShowStreakCelebration() {
        // Only show if no other modals are showing and conditions are met
        guard !showLevelUpModal, !showRankUpModal, !showItemDropModal else {
            return // Wait for other modals to finish
        }
        
        guard shouldShowStreakCelebration() else {
            return
        }
        
        // Mark as shown today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let todayString = dateFormatter.string(from: Date())
        UserDefaults.standard.set(todayString, forKey: streakCelebrationKey)
        
        // Show the modal
        showStreakCelebration = true
    }
    
    private func showStreakCelebrationManually() {
        // Manual trigger - bypass once-per-day check
        // Only check if data is loaded and streak > 0
        guard !progressManager.isLoading, progressManager.currentStreak > 0 else {
            return
        }
        
        // Only show if no other modals are showing
        guard !showLevelUpModal, !showRankUpModal, !showItemDropModal else {
            return
        }
        
        // Show the modal (don't update UserDefaults for manual triggers)
        showStreakCelebration = true
    }
    
    private func refreshData() async {
        isRefreshing = true
        await progressManager.loadProgress()
        isRefreshing = false
    }
}

// MARK: - Level Up Modal

struct LevelUpModalView: View {
    let oldLevel: Int
    let newLevel: Int
    let rankUp: (oldRank: RankInfo, newRank: RankInfo)?  // Keep for backward compatibility but won't be used
    let onDismiss: () -> Void
    
    // Animation state variables
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    @State private var borderOpacity: Double = 0
    @State private var levelScale: CGFloat = 0.5
    @State private var levelGlow: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var showConfetti: Bool = false
    @State private var gradientRotation: Double = 0
    
    // Gold theme color
    private let goldColor = Color(hex: "#FFD700")
    
    // Gradient colors for border and confetti
    private let gradientColors = [
        Color(hex: "#F173FF"),
        Color(hex: "#6FE4FF"),
        Color(hex: "#FFE66F"),
        Color(hex: "#F173FF")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background: Semi-transparent black overlay
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // Glassmorphic card container
                VStack(spacing: 24) {
                    // Header
                    Text("LEVEL UP! ⚡")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 2)
                        .opacity(contentOpacity)
                    
                    // Hero Element: NEW level number ONLY
                    Text("\(newLevel)")
                        .font(.system(size: 90, weight: .bold))
                        .foregroundColor(goldColor)
                        .shadow(color: goldColor.opacity(levelGlow), radius: 30, x: 0, y: 0)
                        .scaleEffect(levelScale)
                        .padding(.vertical, 20)
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(goldColor)
                            .cornerRadius(25)
                            .shadow(color: goldColor.opacity(0.6), radius: 15, x: 0, y: 5)
                    }
                    .opacity(contentOpacity)
                }
                .padding(.top, 50)
                .padding(.bottom, 70)
                .padding(.horizontal, 30)
                .scaleEffect(cardScale)
                .background(
                    // Glassmorphic background
                    ZStack {
                        // Dark semi-transparent background
                        Color(hex: "#14141E")
                            .opacity(0.85)
                        
                        // Frosted glass effect
                        Color.white.opacity(0.02)
                    }
                )
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    // Animated gradient border
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            AngularGradient(
                                colors: gradientColors,
                                center: .center,
                                angle: .degrees(gradientRotation)
                            ),
                            lineWidth: 3.5
                        )
                        .opacity(borderOpacity)
                )
                // Soft outer glow - gradient colors
                .shadow(color: Color(hex: "#F173FF").opacity(0.25 * borderOpacity), radius: 35, x: 0, y: 0)
                .shadow(color: Color(hex: "#6FE4FF").opacity(0.25 * borderOpacity), radius: 35, x: 0, y: 0)
                .shadow(color: Color(hex: "#FFE66F").opacity(0.25 * borderOpacity), radius: 35, x: 0, y: 0)
                // Existing shadows
                .shadow(color: goldColor.opacity(0.4 * borderOpacity), radius: 25, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 20)
                
                // Burst confetti overlay - ON TOP of card
                if showConfetti {
                    BurstConfettiView(
                        colors: [
                            Color(hex: "#F173FF"),
                            Color(hex: "#6FE4FF"),
                            Color(hex: "#FFE66F"),
                            goldColor
                        ],
                        particleCount: 80
                    )
                    .allowsHitTesting(false)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Start gradient rotation animation (continuous)
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        // Phase 1: Background fade-in (0.2s)
        withAnimation(.easeInOut(duration: 0.2)) {
            backgroundOpacity = 0.5
        }
        
        // Phase 2: Card entrance with spring (0.4s, starts at 0.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1.0
                borderOpacity = 1.0
            }
        }
        
        // Phase 3: Level number POP (0.6s, starts at 0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // Scale from 0.5x → 1.2x → 1.0x with glow burst
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                levelScale = 1.2
                levelGlow = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    levelScale = 1.0
                }
            }
            
            // Start confetti explosion (starts at 0.5s, slightly after pop begins)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
        }
        
        // Phase 4: Content fade-in (0.4s, starts at 0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeIn(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Rank Up Modal

struct RankUpModalView: View {
    let oldRank: RankInfo
    let newRank: RankInfo
    let onDismiss: () -> Void
    
    // Animation state variables
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    @State private var borderOpacity: Double = 0
    @State private var rankScale: CGFloat = 0.5
    @State private var rankGlow: CGFloat = 0
    @State private var contentOpacity: Double = 0
    @State private var showSparkles: Bool = false
    @State private var gradientRotation: Double = 0
    
    // Rank color (dynamic based on new rank)
    private var rankColor: Color {
        newRank.swiftUIColor
    }
    
    // Gradient colors for border (based on rank color)
    private var gradientColors: [Color] {
        [
            rankColor.opacity(0.9),
            rankColor.opacity(0.7),
            rankColor.opacity(0.5),
            rankColor.opacity(0.9)
        ]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background: Semi-transparent black overlay
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // Glassmorphic card container
                VStack(spacing: 24) {
                    // Header - "⭐ RANK UP!"
                    Text("⭐ RANK UP!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(rankColor)
                        .shadow(color: rankColor.opacity(0.5), radius: 8, x: 0, y: 2)
                        .opacity(contentOpacity)
                    
                    // Hero Element: NEW rank (e.g., "D-Rank")
                    Text("\(newRank.code)-Rank")
                        .font(.system(size: 90, weight: .bold))
                        .foregroundColor(rankColor)
                        .shadow(color: rankColor.opacity(rankGlow), radius: 30, x: 0, y: 0)
                        .scaleEffect(rankScale)
                        .padding(.vertical, 20)
                    
                    Spacer()
                    
                    // Continue button (rank color background)
                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(rankColor)
                            .cornerRadius(25)
                            .shadow(color: rankColor.opacity(0.6), radius: 15, x: 0, y: 5)
                    }
                    .opacity(contentOpacity)
                }
                .padding(.top, 50)
                .padding(.bottom, 70)
                .padding(.horizontal, 30)
                .scaleEffect(cardScale)
                .background(
                    // Glassmorphic background (same as level up)
                    ZStack {
                        Color(hex: "#14141E")
                            .opacity(0.85)
                        
                        // Frosted glass effect
                        Color.white.opacity(0.02)
                    }
                )
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    // Animated gradient border (rank color)
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            AngularGradient(
                                colors: gradientColors,
                                center: .center,
                                angle: .degrees(gradientRotation)
                            ),
                            lineWidth: 3.5
                        )
                        .opacity(borderOpacity)
                )
                // Soft outer glow - rank color
                .shadow(color: rankColor.opacity(0.4 * borderOpacity), radius: 35, x: 0, y: 0)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 20)
                
                // Sparkle overlay - DIFFERENT from confetti
                if showSparkles {
                    SparkleRainView(
                        primaryColor: rankColor,
                        particleCount: 60
                    )
                    .allowsHitTesting(false)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Start gradient rotation animation (continuous)
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            gradientRotation = 360
        }
        
        // Phase 1: Background fade-in (0.2s)
        withAnimation(.easeInOut(duration: 0.2)) {
            backgroundOpacity = 0.5
        }
        
        // Phase 2: Card entrance with spring (0.4s, starts at 0.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                cardScale = 1.0
                borderOpacity = 1.0
            }
        }
        
        // Phase 3: Rank POP (0.6s, starts at 0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // Scale from 0.5x → 1.2x → 1.0x with glow burst
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                rankScale = 1.2
                rankGlow = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    rankScale = 1.0
                }
            }
            
            // Start sparkles (starts at 0.5s, slightly after pop begins)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showSparkles = true
            }
        }
        
        // Phase 4: Content fade-in (0.4s, starts at 0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeIn(duration: 0.4)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Burst Confetti System (Level Up - Explosive Outward Burst)

struct BurstParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double
    var rotationSpeed: Double
    var opacity: Double = 1.0
    var color: Color
    var size: CGFloat
    var isRectangle: Bool
}

struct BurstConfettiView: View {
    let colors: [Color]
    let particleCount: Int
    @State private var particles: [BurstParticle] = []
    @State private var startTime: Date = Date()
    @State private var timer: Timer?
    
    init(colors: [Color], particleCount: Int = 80) {
        self.colors = colors
        self.particleCount = particleCount
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Group {
                        if particle.isRectangle {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size * 0.4)
                        } else {
                            Circle()
                                .fill(particle.color)
                                .frame(width: particle.size, height: particle.size)
                        }
                    }
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                startTimer(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height * 0.35 // Center of the level number area
        
        particles = (0..<particleCount).map { _ in
            // Full 360 degree burst
            let angle = Double.random(in: 0...(2 * Double.pi))
            // Higher velocity for explosive feel
            let speed = Double.random(in: 150...350)
            
            let randomColor = colors.randomElement() ?? colors[0]
            
            return BurstParticle(
                position: CGPoint(
                    x: centerX + CGFloat.random(in: -10...10),
                    y: centerY + CGFloat.random(in: -10...10)
                ),
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                color: randomColor,
                size: CGFloat.random(in: 8...14),
                isRectangle: Bool.random()
            )
        }
    }
    
    private func startTimer(in size: CGSize) {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles(in: size)
        }
    }
    
    private func updateParticles(in size: CGSize) {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Longer duration: 1.8s
        if elapsed > 1.8 {
            timer?.invalidate()
            return
        }
        
        for i in particles.indices {
            // Apply gravity (pulls down)
            particles[i].velocity.dy += 280 * 0.016
            
            // Apply air resistance (slows down over time)
            particles[i].velocity.dx *= 0.99
            particles[i].velocity.dy *= 0.99
            
            // Update position
            particles[i].position.x += particles[i].velocity.dx * 0.016
            particles[i].position.y += particles[i].velocity.dy * 0.016
            
            // Update rotation
            particles[i].rotation += particles[i].rotationSpeed * 0.016
            
            // Fade out after 1.2s
            if elapsed > 1.2 {
                let fadeProgress = min((elapsed - 1.2) / 0.6, 1.0)
                particles[i].opacity = 1.0 - fadeProgress
            }
        }
        
        // Remove off-screen or faded particles
        particles = particles.filter { particle in
            particle.position.y < size.height + 100 &&
            particle.position.y > -100 &&
            particle.position.x > -100 &&
            particle.position.x < size.width + 100 &&
            particle.opacity > 0.01
        }
    }
}

// MARK: - Sparkle Rain System (Item Drop - Magical Falling Sparkles)

struct SparkleParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double
    var rotationSpeed: Double
    var opacity: Double
    var color: Color
    var size: CGFloat
    var twinklePhase: Double
    var twinkleSpeed: Double
}

struct SparkleRainView: View {
    let primaryColor: Color
    let particleCount: Int
    @State private var particles: [SparkleParticle] = []
    @State private var startTime: Date = Date()
    @State private var timer: Timer?
    
    init(primaryColor: Color, particleCount: Int = 50) {
        self.primaryColor = primaryColor
        self.particleCount = particleCount
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    // Diamond/star shape for magical feel
                    Image(systemName: "sparkle")
                        .font(.system(size: particle.size))
                        .foregroundColor(particle.color)
                        .position(particle.position)
                        .opacity(particle.opacity * (0.6 + 0.4 * sin(particle.twinklePhase)))
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
                startTimer(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func initializeParticles(in size: CGSize) {
        // Colors: primary color + white/silver accents
        let sparkleColors: [Color] = [
            primaryColor,
            primaryColor.opacity(0.8),
            .white,
            Color(hex: "#E8E8E8"),
            Color(hex: "#FFD700").opacity(0.6)
        ]
        
        particles = (0..<particleCount).map { _ in
            let randomColor = sparkleColors.randomElement() ?? primaryColor
            
            return SparkleParticle(
                position: CGPoint(
                    x: CGFloat.random(in: 20...(size.width - 20)),
                    y: CGFloat.random(in: -50...(-10)) // Start above the view
                ),
                velocity: CGVector(
                    dx: CGFloat.random(in: -20...20), // Slight horizontal drift
                    dy: CGFloat.random(in: 40...80) // Gentle downward fall
                ),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -60...60),
                opacity: Double.random(in: 0.7...1.0),
                color: randomColor,
                size: CGFloat.random(in: 6...12),
                twinklePhase: Double.random(in: 0...(2 * Double.pi)),
                twinkleSpeed: Double.random(in: 4...8)
            )
        }
    }
    
    private func startTimer(in size: CGSize) {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles(in: size)
        }
    }
    
    private func updateParticles(in size: CGSize) {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Longer duration: 2.5s for gentle effect
        if elapsed > 2.5 {
            timer?.invalidate()
            return
        }
        
        for i in particles.indices {
            // Gentle swaying motion (sine wave)
            let swayAmount = sin(elapsed * 2 + Double(i) * 0.5) * 15
            particles[i].velocity.dx = CGFloat(swayAmount)
            
            // Update position
            particles[i].position.x += particles[i].velocity.dx * 0.016
            particles[i].position.y += particles[i].velocity.dy * 0.016
            
            // Update rotation (slow, gentle)
            particles[i].rotation += particles[i].rotationSpeed * 0.016
            
            // Update twinkle phase
            particles[i].twinklePhase += particles[i].twinkleSpeed * 0.016
            
            // Fade out after 1.8s
            if elapsed > 1.8 {
                let fadeProgress = min((elapsed - 1.8) / 0.7, 1.0)
                particles[i].opacity = (1.0 - fadeProgress) * Double.random(in: 0.7...1.0)
            }
        }
        
        // Remove off-screen or faded particles
        particles = particles.filter { particle in
            particle.position.y < size.height + 50 &&
            particle.opacity > 0.01
        }
    }
}

// MARK: - Item Drop Modal

struct ItemDropModalView: View {
    let item: PortalItem
    let onDismiss: () -> Void
    
    // Animation state variables
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    @State private var borderOpacity: Double = 0
    @State private var itemScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var showConfetti: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background: Semi-transparent black overlay
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // Glassmorphic card container
                VStack(spacing: 16) {
                    // Title
                    Text("NEW ITEM! 🎁")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 2)
                        .opacity(contentOpacity)
                    
                    // Rank badge
                    Text("\(item.rolledRank)-RANK")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(item.rankColor)
                        .cornerRadius(10)
                        .shadow(color: item.rankColor.opacity(0.5), radius: 8, x: 0, y: 0)
                        .opacity(contentOpacity)
                    
                    // Item icon (separate for pop animation)
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
                                .shadow(color: item.rankColor.opacity(0.6), radius: 20, x: 0, y: 0)
                        case .failure:
                            Image(systemName: "gift.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.8))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .scaleEffect(itemScale)
                    
                    // Item name
                    Text(item.name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .opacity(contentOpacity)
                    
                    // Stat bonus
                    Text("+\(item.statValue) \(item.statType)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(item.rankColor.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(item.rankColor.opacity(0.5), lineWidth: 1)
                        )
                        .opacity(contentOpacity)
                    
                    // Collect button
                    Button(action: onDismiss) {
                        Text("Collect")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(item.rankColor)
                            .cornerRadius(25)
                            .shadow(color: item.rankColor.opacity(0.6), radius: 15, x: 0, y: 5)
                    }
                    .opacity(contentOpacity)
                }
                .padding(.top, 30)
                .padding(.bottom, 30)
                .padding(.horizontal, 30)
                .scaleEffect(cardScale)
                .background(
                    // Glassmorphic background
                    ZStack {
                        // Dark semi-transparent background
                        Color(hex: "#14141E")
                            .opacity(0.85)
                        
                        // Frosted glass effect
                        Color.white.opacity(0.02)
                    }
                )
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    // Rank-colored border
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(item.rankColor.opacity(borderOpacity), lineWidth: 2.5)
                )
                .shadow(color: item.rankColor.opacity(0.4 * borderOpacity), radius: 25, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 20)
                
                // Sparkle rain overlay - ON TOP of card
                if showConfetti {
                    SparkleRainView(
                        primaryColor: item.rankColor,
                        particleCount: 50
                    )
                    .allowsHitTesting(false)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Phase 1: Modal Fade In (0.3s)
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0.45
        }
        
        // Phase 2: Card Entrance (0.5s, starts at 0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardScale = 1.0
                borderOpacity = 1.0
            }
        }
        
        // Phase 3: Item Pop (0.4s, starts at 0.5s) + Confetti (starts at 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Item pop animation with subtle bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                itemScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    itemScale = 1.0
                }
            }
            
            // Start confetti slightly after item pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
        }
        
        // Phase 5: Content Fade (0.3s, starts at 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

// MARK: - Streak Celebration Modal

struct StreakCelebrationModalView: View {
    let streakCount: Int
    let onDismiss: () -> Void
    
    @State private var flameScale: CGFloat = 1.0
    @State private var flameGlow: CGFloat = 0.5
    @State private var selectedMessage: String = ""
    
    private let motivationalMessages = [
        "Way to show up! Keep the habit strong",
        "One step closer. Every day counts.",
        "You got this! Maintain that perfect record.",
        "Future You is proud! Keep reaching for your goal.",
        "Streak secured! The momentum is yours.",
        "You're on fire! Don't let the flame die out."
    ]
    
    private var calendarDays: [(date: Date, dayAbbrev: String, isCompleted: Bool, isToday: Bool, isFuture: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find Monday of current week
        let weekday = calendar.component(.weekday, from: today)
        // Convert: Sunday=1, Monday=2, ..., Saturday=7
        // We want Monday=0, so: (weekday + 5) % 7
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        
        var days: [(date: Date, dayAbbrev: String, isCompleted: Bool, isToday: Bool, isFuture: Bool)] = []
        
        // Day abbreviations for Mon-Sun
        let dayAbbrevs = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        
        // Generate 7 days starting from Monday
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                let dateStart = calendar.startOfDay(for: date)
                let isToday = calendar.isDateInToday(date)
                let isFuture = dateStart > today
                
                // Calculate if this day is within the streak
                // Streak includes today and the previous (streakCount - 1) days
                // daysAgo: positive = days in the past, 0 = today, negative = future
                let daysAgo = calendar.dateComponents([.day], from: dateStart, to: today).day ?? 0
                // Completed if: not future AND within streak range (0 to streakCount-1)
                let isCompleted = daysAgo >= 0 && daysAgo < streakCount
                
                days.append((
                    date: date,
                    dayAbbrev: dayAbbrevs[i],
                    isCompleted: isCompleted,
                    isToday: isToday,
                    isFuture: isFuture
                ))
            }
        }
        
        return days
    }
    
    var body: some View {
        ZStack {
            // Background - dark theme
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                // Large animated flame icon with streak number
                VStack(spacing: 16) {
                    Text("🔥")
                        .font(.system(size: 80))
                        .scaleEffect(flameScale)
                        .shadow(color: Color(hex: "#FF6B35").opacity(flameGlow), radius: 20, x: 0, y: 0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                flameScale = 1.15
                            }
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                flameGlow = 1.0
                            }
                        }
                    
                    // Streak number
                    Text("\(streakCount)")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.white)
                    
                    // "days streak!" text
                    Text("days streak!")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#FF6B35"))
                }
                
                // 7-day calendar
                VStack(spacing: 12) {
                    Text("Last 7 Days")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    
                    HStack(spacing: 10) {
                        ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, day in
                            VStack(spacing: 6) {
                                // Day circle
                                ZStack {
                                    Circle()
                                        .fill(day.isCompleted || day.isToday ? Color(hex: "#FF6B35") : Color(hex: "#374151"))
                                        .frame(width: 40, height: 40)
                                    
                                    if day.isToday {
                                        Text("🔥")
                                            .font(.system(size: 18))
                                    } else if day.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Day label
                                Text(day.dayAbbrev)
                                    .font(.caption)
                                    .foregroundColor(day.isCompleted || day.isToday ? Color(hex: "#FF6B35") : Color(hex: "#9CA3AF"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                
                // Motivational text
                Text(selectedMessage)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .onAppear {
                        // Set message once when modal appears
                        if selectedMessage.isEmpty {
                            selectedMessage = motivationalMessages.randomElement() ?? motivationalMessages[0]
                        }
                    }
                
                Spacer()
                
                // Continue button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FF6B35"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#FF6B35").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Focus Session Settings Model

enum FocusMode: String, Codable {
    case stopwatch, timer, pomodoro
}

struct FocusSessionSettings: Codable {
    var mode: FocusMode
    var timerDuration: Int // minutes (10-120)
    var pomodoroCount: Int // number of pomodoros (1-10)
    
    static let userDefaultsKey = "FocusSessionSettings"
    
    static func load() -> FocusSessionSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(FocusSessionSettings.self, from: data) else {
            return FocusSessionSettings(mode: .stopwatch, timerDuration: 25, pomodoroCount: 1)
        }
        return settings
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}

// MARK: - Focus Configuration Modal

struct FocusConfigurationModal: View {
    @Binding var navigationPath: NavigationPath
    @Binding var showPortalTransition: Bool
    @Binding var pendingNavigation: String?
    let onPortalTransitionComplete: (@escaping () -> Void) -> Void
    @State private var selectedTag: String? = nil
    @State private var focusSettings = FocusSessionSettings.load()
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @StateObject private var revenueCat = RevenueCatManager.shared
    @State private var showPaywall = false
    // Note: FamilyActivityPicker kept commented out in FocusConfigurationModal
    // Users configure allowed apps in Settings/Profile instead
    @Environment(\.dismiss) var dismiss
    
    private let focusTags = ["Deep Focus", "Study", "Reading", "Creative"]
    
    var body: some View {
        ZStack {
            // Background - dark theme
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Title
                    Text("What would you like to focus on?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                    
                    // Horizontal scrolling pill buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(focusTags, id: \.self) { tag in
                                Button(action: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    // Toggle selection
                                    if selectedTag == tag {
                                        selectedTag = nil
                                    } else {
                                        selectedTag = tag
                                    }
                                }) {
                                    Text(tag)
                                        .font(.headline)
                                        .foregroundColor(selectedTag == tag ? .white : Color(hex: "#9CA3AF"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedTag == tag ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 8)
                    
                    // Mode section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mode")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        // Mode selector - connected tabs
                        HStack(spacing: 0) {
                            // Stopwatch tab
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                focusSettings.mode = .stopwatch
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "stopwatch")
                                        .font(.system(size: 16))
                                    Text("Stopwatch")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(focusSettings.mode == .stopwatch ? .white : Color(hex: "#9CA3AF"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(focusSettings.mode == .stopwatch ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                                .clipShape(
                                    .rect(
                                        topLeadingRadius: 20,
                                        bottomLeadingRadius: 20,
                                        bottomTrailingRadius: 0,
                                        topTrailingRadius: 0
                                    )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Timer tab
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Check if user is Pro, if not show paywall
                                if !revenueCat.isPro {
                                    showPaywall = true
                                } else {
                                    focusSettings.mode = .timer
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 16))
                                    Text("Timer")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(focusSettings.mode == .timer ? .white : Color(hex: "#9CA3AF"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(focusSettings.mode == .timer ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Pomodoro tab
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Check if user is Pro, if not show paywall
                                if !revenueCat.isPro {
                                    showPaywall = true
                                } else {
                                    focusSettings.mode = .pomodoro
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 16))
                                    Text("Pomodoro")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(focusSettings.mode == .pomodoro ? .white : Color(hex: "#9CA3AF"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(focusSettings.mode == .pomodoro ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                                .clipShape(
                                    .rect(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 0,
                                        bottomTrailingRadius: 20,
                                        topTrailingRadius: 20
                                    )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color(hex: "#374151"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }
                    
                    // Duration section (conditional) - wrapped in fixed height container
                    VStack(alignment: .leading, spacing: 12) {
                        if focusSettings.mode == .stopwatch {
                            Text("Time counts up until you stop.")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                        } else if focusSettings.mode == .timer {
                            HStack {
                                Text("Duration")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(focusSettings.timerDuration)min")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#22C55E"))
                            }
                            .padding(.horizontal, 20)
                            
                            Slider(value: Binding(
                                get: { Double(focusSettings.timerDuration) },
                                set: { newValue in
                                    let rounded = Int(newValue)
                                    if rounded != focusSettings.timerDuration {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                    focusSettings.timerDuration = rounded
                                }
                            ), in: 10...120, step: 1)
                            .tint(Color(hex: "#FF9500"))
                            .padding(.horizontal, 20)
                            
                            HStack {
                                Text("10min")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                Spacer()
                                Text("120min")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }
                            .padding(.horizontal, 20)
                        } else if focusSettings.mode == .pomodoro {
                            Text("Duration")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            // Compact pomodoro picker
                            Picker("Pomodoros", selection: $focusSettings.pomodoroCount) {
                                ForEach(1...10, id: \.self) { count in
                                    Text("\(count) Pomodoro\(count > 1 ? "s" : "")")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .tag(count)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .colorScheme(.dark)
                            .padding(.horizontal, 20)
                        }
                    }
                    .frame(minHeight: 120)
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // Start session button
                    Button(action: {
                        focusSettings.save()
                        // Set pending navigation destination
                        pendingNavigation = "FocusSession"
                        
                        // Set up the navigation callback for when portal transition completes
                        onPortalTransitionComplete {
                            // Disable the default navigation animation
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                navigationPath.append("FocusSession")
                            }
                        }
                        
                        // Dismiss modal instantly
                        dismiss()
                        // Trigger portal transition after a tiny delay to ensure modal is dismissed
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showPortalTransition = true
                        }
                    }) {
                        Text("Start session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#22C55E"))
                            .cornerRadius(25)
                            .shadow(color: Color(hex: "#22C55E").opacity(0.6), radius: 15, x: 0, y: 0)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large, .medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        // Note: FamilyActivityPicker kept commented out here - users configure allowed apps in Settings/Profile instead
        /*
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: selection) { _, newSelection in
            let applicationTokens = newSelection.applicationTokens
            appBlockingManager.setBlockedApplications(applicationTokens, selection: newSelection)
            selection = newSelection
        }
        .onAppear {
            selection = appBlockingManager.selectedActivity
        }
        */
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
                        HStack {
                            if isRequestingPermission {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                                Text("Requesting...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            } else {
                                Text("Block Apps")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#6B46C1"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                    }
                    .disabled(isRequestingPermission)
                    .opacity(isRequestingPermission ? 0.8 : 1.0)
                    
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
    HomeView(
        showPortalTransition: .constant(false),
        onPortalTransitionComplete: { _ in }
    )
        .environmentObject(UserProgressManager.shared)
}
