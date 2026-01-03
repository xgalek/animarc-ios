//
//  PortalRaidView.swift
//  Animarc IOS
//
//  Portal raid system - attack bosses and track progress
//

import SwiftUI

// MARK: - Raid Result Data

struct RaidResultData: Identifiable {
    let id = UUID()
    let result: RaidAttemptResult
    let boss: PortalBoss
    let progress: PortalRaidProgress
    let rewards: (xp: Int, gold: Int)?
}

// MARK: - Portal Raid View

struct PortalRaidView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var revenueCat = RevenueCatManager.shared
    @StateObject private var errorManager = ErrorManager.shared
    
    @State private var selectedBoss: PortalBoss? = nil
    @State private var contentAppeared = false
    @State private var raidResultData: RaidResultData? = nil
    @State private var showBattleAnimation = false
    @State private var pendingRaidData: (boss: PortalBoss, progress: PortalRaidProgress, userStats: BattlerStats, bossStats: BattlerStats)? = nil
    
    @State private var availableBosses: [PortalBoss] = []
    @State private var bossProgress: [UUID: PortalRaidProgress] = [:]
    @State private var portalAttempts: Int = 50
    @State private var bossAttemptsRemaining: Int = 1
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showPaywall = false
    
    // Timer for Pro users countdown
    @State private var timeUntilReset: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>? = nil
    
    // Cached data for optimistic UI
    @State private var cachedBosses: [PortalBoss] = []
    @State private var cachedProgress: [UUID: PortalRaidProgress] = [:]
    @State private var cachedAttempts: Int = 50
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#191919")
                .ignoresSafeArea()
            
            if let error = errorMessage {
                VStack(spacing: 16) {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Button("Retry") {
                        Task {
                            await loadData()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color(hex: "#F59E0B"))
                    .cornerRadius(8)
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "#374151").opacity(0.3))
                                .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        Text("Portal Raids")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Daily boss attempts counter
                        VStack(alignment: .trailing, spacing: 2) {
                            if isLoading && availableBosses.isEmpty {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(Color(hex: "#F59E0B"))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("\(bossAttemptsRemaining)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(bossAttemptsRemaining > 0 ? Color(hex: "#F59E0B") : Color(hex: "#DC2626"))
                            }
                            Text("DAILY BOSS ATTEMPTS")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(0.3)
                        }
                        .frame(width: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .background(Color(hex: "#191919").opacity(0.95))
                    
                    // Scrollable boss list
                    ScrollView {
                        if availableBosses.isEmpty && isLoading {
                            // Show empty state while loading for first time
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(Color(hex: "#F59E0B"))
                                Text("Opening portals...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            VStack(spacing: 20) {
                                ForEach(availableBosses) { boss in
                                    PortalBossCard(
                                        boss: boss,
                                        progress: bossProgress[boss.id],
                                        userStats: calculateUserStats(),
                                        isSelected: selectedBoss?.id == boss.id,
                                        portalAttempts: bossAttemptsRemaining,
                                        onTap: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            selectedBoss = boss
                                        }
                                    )
                                    .opacity(contentAppeared ? 1 : 0)
                                    .offset(y: contentAppeared ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.5, dampingFraction: 0.8)
                                            .delay(Double(availableBosses.firstIndex(where: { $0.id == boss.id }) ?? 0) * 0.08),
                                        value: contentAppeared
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 120)
                        }
                    }
                    
                    Spacer()
                }
                
                // Fixed bottom button
                VStack {
                    Spacer()
                    
                    Button(action: {
                        if bossAttemptsRemaining <= 0 {
                            // No attempts remaining
                            if revenueCat.isPro {
                                // Pro user: show toast notification
                                errorManager.showInfo("Your character is resting. Ready for another fight tomorrow!")
                            } else {
                                // Free user: show paywall
                                showPaywall = true
                            }
                        } else {
                            // Has attempts: start raid
                            startRaid()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if bossAttemptsRemaining <= 0 {
                                // Exhausted state
                                if revenueCat.isPro {
                                    // Pro: moon icon + timer
                                    Image(systemName: "moon.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Resting... Next Attack in \(formatTimeRemaining(timeUntilReset))")
                                        .font(.system(size: 16, weight: .bold))
                                } else {
                                    // Free: crown icon + Go Pro text
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Go Pro for +2 Daily Attempts")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            } else {
                                // Ready state: bolt icon + Attack Boss
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("ATTACK BOSS")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FACC15"), Color(hex: "#F97316")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "#F97316").opacity(0.3), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    // Remove disabled state - button is always clickable
                    .opacity(selectedBoss == nil ? 0.6 : 1.0)
                }
                
                // Battle animation overlay
                if showBattleAnimation, let raidData = pendingRaidData {
                    BattleAnimationView(
                        userAvatar: "ProfileIcon/profile image",
                        opponentAvatar: raidData.boss.imageName,
                        userStats: raidData.userStats,
                        opponentStats: raidData.bossStats,
                        onComplete: { battleResult in
                            // Animation complete, execute raid attempt
                            // Note: battleResult is calculated by BattleAnimationView but we ignore it
                            // and calculate raid damage separately using PortalService
                            Task {
                                await executeRaidAttempt(raidData: raidData)
                            }
                        }
                    )
                    .transition(.opacity)
                    .zIndex(999)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $raidResultData) { data in
            PortalRaidResultView(
                result: data.result,
                boss: data.boss,
                progress: data.progress,
                rewards: data.rewards,
                onAttackAgain: {
                    raidResultData = nil
                },
                onReturnHome: {
                    raidResultData = nil
                    dismiss()
                    
                    // Refresh progress manager and boss attempts in background
                    Task {
                        await progressManager.refreshProgress()
                        
                        // Also refresh boss attempts from database
                        guard let session = try? await SupabaseManager.shared.client.auth.session else {
                            return
                        }
                        let userId = session.user.id
                        let isPro = await MainActor.run { revenueCat.isPro }
                        
                        do {
                            let remainingBossAttempts = try await SupabaseManager.shared.getRemainingBossAttempts(userId: userId, isPro: isPro)
                            await MainActor.run {
                                bossAttemptsRemaining = remainingBossAttempts
                            }
                        } catch {
                            print("Failed to refresh boss attempts: \(error)")
                        }
                    }
                }
            )
            .environmentObject(progressManager)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            await loadData()
        }
        .onAppear {
            // Content appearance is now handled in loadData() after data loads
            // This ensures smooth fade-in after data is ready
            // Portal attempts are always fetched fresh in loadData(), no need to refresh here
            
            // Start timer if Pro user has exhausted attempts
            startTimer()
        }
        .onDisappear {
            // Stop timer when view disappears
            stopTimer()
        }
        .onChange(of: bossAttemptsRemaining) { oldValue, newValue in
            // Restart timer when attempts change (e.g., exhausted or refreshed)
            if revenueCat.isPro && newValue <= 0 {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onChange(of: revenueCat.isPro) { oldValue, newValue in
            // Restart timer when Pro status changes
            if newValue && bossAttemptsRemaining <= 0 {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .toast(errorManager: errorManager)
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        // Show cached data immediately if available (optimistic UI)
        if !cachedBosses.isEmpty {
            await MainActor.run {
                availableBosses = cachedBosses
                bossProgress = cachedProgress
                // DON'T use cached attempts - always fetch fresh portal attempts from database
                // portalAttempts will be set after fetching fresh data
                // Note: bossAttemptsRemaining will be loaded from database
                isLoading = false // Hide loading immediately
                contentAppeared = true
                
                // Auto-select first boss if none selected
                if selectedBoss == nil && !availableBosses.isEmpty {
                    selectedBoss = availableBosses[0]
                }
            }
        } else {
            isLoading = true
        }
        
        errorMessage = nil
        
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                await MainActor.run {
                    errorMessage = "Not authenticated"
                    isLoading = false
                }
                return
            }
            let userId = session.user.id
            
            // Load user progress
            guard let progress = progressManager.userProgress else {
                await MainActor.run {
                    errorMessage = "User progress not loaded"
                    isLoading = false
                }
                return
            }
            
            // Run independent database calls in parallel for better performance
            let isPro = await MainActor.run { revenueCat.isPro }
            
            // Wrap each task individually to identify which one fails
            let fetchedAttempts: Int
            let remainingBossAttempts: Int
            let allUserProgress: [PortalRaidProgress]
            let allBosses: [PortalBoss]
            
            do {
                fetchedAttempts = try await SupabaseManager.shared.checkAndResetDailyAttempts(userId: userId)
            } catch {
                print("❌ Error fetching attempts: \(error)")
                throw error
            }
            
            do {
                remainingBossAttempts = try await SupabaseManager.shared.getRemainingBossAttempts(userId: userId, isPro: isPro)
            } catch {
                print("❌ Error fetching boss attempts: \(error)")
                throw error
            }
            
            do {
                allUserProgress = try await SupabaseManager.shared.fetchPortalProgress(userId: userId)
            } catch {
                print("❌ Error fetching portal progress: \(error)")
                throw error
            }
            
            do {
                allBosses = try await SupabaseManager.shared.fetchAvailablePortalBosses(userRank: progress.currentRank)
                print("✅ Successfully fetched \(allBosses.count) bosses")
            } catch {
                print("❌ Error fetching portal bosses: \(error)")
                print("Error details: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    print("Decoding error: \(decodingError)")
                }
                throw error
            }
            
            // Process results
            let completedBossIds = Set(allUserProgress.filter { $0.completed }.map { $0.portalBossId })
            
            // Separate bosses into: weakened (have progress but not completed) and new (no progress)
            let weakenedBossIds = Set(allUserProgress.filter { !$0.completed && $0.currentDamage > 0 }.map { $0.portalBossId })
            let weakenedBosses = allBosses.filter { weakenedBossIds.contains($0.id) }
            let newBosses = allBosses.filter { !completedBossIds.contains($0.id) && !weakenedBossIds.contains($0.id) }
            
            // Always include all weakened bosses first
            var selectedBosses: [PortalBoss] = []
            selectedBosses.append(contentsOf: weakenedBosses)
            
            // Fill remaining slots with new bosses using existing logic
            let remainingSlots = max(0, 5 - selectedBosses.count)
            if remainingSlots > 0 {
                let additionalBosses = PortalService.generateAvailablePortals(
                    userLevel: progress.currentLevel,
                    userRank: progress.currentRank,
                    allBosses: newBosses
                )
                // Take only what we need to fill remaining slots
                selectedBosses.append(contentsOf: Array(additionalBosses.prefix(remainingSlots)))
            }
            
            // Limit to 5 bosses total (in case we have more than 5 weakened bosses)
            selectedBosses = Array(selectedBosses.prefix(5))
            
            // Build progress map efficiently
            var progressMap: [UUID: PortalRaidProgress] = [:]
            let existingProgressMap = Dictionary(grouping: allUserProgress.filter { !$0.completed }, by: { $0.portalBossId })
            
            // Create missing progress entries (could be parallelized further if needed)
            for boss in selectedBosses {
                if let existing = existingProgressMap[boss.id]?.first {
                    progressMap[boss.id] = existing
                } else {
                    // Create new progress entry
                    let maxHp = PortalService.calculateBossHP(
                        rank: boss.rank,
                        specialization: boss.specialization,
                        level: RankService.getRankForLevel(progress.currentLevel).minLevel
                    )
                    let newProgress = try await SupabaseManager.shared.createPortalProgress(
                        userId: userId,
                        bossId: boss.id,
                        maxHp: maxHp
                    )
                    progressMap[boss.id] = newProgress
                }
            }
            
            // Update UI with fresh data
            await MainActor.run {
                // Update cache
                cachedBosses = selectedBosses
                cachedProgress = progressMap
                cachedAttempts = fetchedAttempts
                
                // Update displayed data
                availableBosses = selectedBosses
                bossProgress = progressMap
                portalAttempts = fetchedAttempts
                bossAttemptsRemaining = remainingBossAttempts  // ← FIX: Actually use the fetched value!
                isLoading = false
                
                // Trigger fade-in animation if not already appeared
                if !contentAppeared {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        contentAppeared = true
                    }
                }
                
                // Auto-select first boss if none selected
                if selectedBoss == nil && !availableBosses.isEmpty {
                    selectedBoss = availableBosses[0]
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // MARK: - Battle Logic
    
    private func calculateUserStats() -> BattlerStats {
        guard let progress = progressManager.userProgress else {
            return BattlerStats(
                health: 150,
                attack: 10,
                defense: 10,
                speed: 10,
                level: 1,
                focusPower: 1000
            )
        }
        
        let fp = UserProgress.calculateFocusPower(progress: progress, equippedItems: [])
        return BattlerStats(
            health: progress.statHealth,
            attack: progress.statAttack,
            defense: progress.statDefense,
            speed: progress.statSpeed,
            level: progress.currentLevel,
            focusPower: fp
        )
    }
    
    private func startRaid() {
        guard let boss = selectedBoss,
              let progress = bossProgress[boss.id] else {
            return
        }
        
        // Check daily boss attempts before starting
        Task {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                return
            }
            let userId = session.user.id
            let isPro = await MainActor.run { revenueCat.isPro }
            
            // Fetch fresh portal attempts from database (don't trust local state)
            do {
                let freshPortalAttempts = try await SupabaseManager.shared.getPortalAttempts(userId: userId)
                await MainActor.run {
                    portalAttempts = freshPortalAttempts
                    cachedAttempts = freshPortalAttempts
                }
                
                // Check portal attempts from fresh database value
                guard freshPortalAttempts > 0 else {
                    // No portal attempts remaining
                    return
                }
            } catch {
                print("Failed to fetch portal attempts: \(error)")
                return
            }
            
            // Check if user can attempt boss (daily boss attempts)
            let canAttempt = try await SupabaseManager.shared.canAttemptBoss(userId: userId, isPro: isPro)
            
            if !canAttempt {
                // Show paywall for free users on 2nd attempt
                await MainActor.run {
                    showPaywall = true
                }
                return
            }
            
            // User has attempts remaining, proceed with battle
            await MainActor.run {
                // Optimistically decrement attempts for instant UI feedback
                bossAttemptsRemaining = max(0, bossAttemptsRemaining - 1)
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                let userStats = calculateUserStats()
                let bossStats = boss.battlerStats
                
                pendingRaidData = (boss: boss, progress: progress, userStats: userStats, bossStats: bossStats)
                showBattleAnimation = true
            }
        }
    }
    
    private func executeRaidAttempt(raidData: (boss: PortalBoss, progress: PortalRaidProgress, userStats: BattlerStats, bossStats: BattlerStats)) async {
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                return
            }
            let userId = session.user.id
            
            // Consume portal attempt
            portalAttempts = try await SupabaseManager.shared.consumePortalAttempt(userId: userId)
            
            // Increment daily boss attempts
            let updatedLimits = try await SupabaseManager.shared.incrementBossAttempts(userId: userId)
            let isPro = await MainActor.run { revenueCat.isPro }
            let maxAttempts = isPro ? 3 : 1
            await MainActor.run {
                bossAttemptsRemaining = max(0, maxAttempts - updatedLimits.bossAttemptsUsed)
            }
            
            // Execute raid attempt
            let result = PortalService.executeRaidAttempt(
                userStats: raidData.userStats,
                bossStats: raidData.bossStats,
                currentProgress: raidData.progress
            )
            
            // Update progress
            var updatedProgress = raidData.progress
            updatedProgress.applyDamage(result.damageDealt)
            
            let savedProgress = try await SupabaseManager.shared.updatePortalProgress(
                userId: userId,
                progressId: updatedProgress.id,
                newDamage: updatedProgress.currentDamage,
                newPercent: updatedProgress.progressPercent
            )
            
            // If boss defeated, mark as completed and award rewards
            var rewards: (xp: Int, gold: Int)? = nil
            if result.bossDefeated {
                _ = try await SupabaseManager.shared.completePortalBoss(userId: userId, progressId: savedProgress.id)
                
                let bossRewards = PortalService.calculateBossRewards(
                    bossRank: raidData.boss.rank,
                    bossLevel: RankService.getBossLevelForRank(rankCode: raidData.boss.rank, seed: raidData.boss.id.hashValue)
                )
                
                // Save old level before updating
                let oldLevel = progressManager.userProgress?.currentLevel ?? 1
                
                // Update user progress with rewards
                let updatedUserProgress = try await SupabaseManager.shared.updateGoldAndXP(
                    userId: userId,
                    goldToAdd: bossRewards.gold,
                    xpToAdd: bossRewards.xp
                )
                
                // Drop portal boss item (non-critical, don't fail if it errors)
                do {
                    let isPro = await MainActor.run { revenueCat.isPro }
                    let droppedItem = try await SupabaseManager.shared.dropPortalBossItem(
                        userId: userId,
                        bossRank: raidData.boss.rank,
                        isPro: isPro
                    )
                    await MainActor.run {
                        progressManager.pendingPortalBossItemDrop = droppedItem
                    }
                } catch {
                    print("Failed to drop portal boss item: \(error)")
                    // Non-critical error, don't show to user
                }
                
                await MainActor.run {
                    progressManager.userProgress = updatedUserProgress
                    
                    // Check for level up and set pending flag so modal can show later
                    let newLevel = updatedUserProgress.currentLevel
                    if newLevel > oldLevel {
                        // Check for rank up
                        if let rankUp = RankService.checkForRankUp(oldLevel: oldLevel, newLevel: newLevel) {
                            progressManager.pendingRankUp = (oldRank: rankUp.oldRank, newRank: rankUp.newRank)
                        }
                        progressManager.pendingLevelUp = (oldLevel: oldLevel, newLevel: newLevel)
                    }
                }
                
                rewards = bossRewards
                
                // Spawn new boss (reload data)
                await loadData()
            } else {
                // Update local progress map
                await MainActor.run {
                    bossProgress[savedProgress.portalBossId] = savedProgress
                }
            }
            
            await MainActor.run {
                showBattleAnimation = false
                raidResultData = RaidResultData(
                    result: result,
                    boss: raidData.boss,
                    progress: savedProgress,
                    rewards: rewards
                )
            }
        } catch {
            await MainActor.run {
                showBattleAnimation = false
                errorMessage = error.localizedDescription
            }
            
            // If battle failed, refresh boss attempts from database to revert optimistic update
            Task {
                guard let session = try? await SupabaseManager.shared.client.auth.session else {
                    return
                }
                let userId = session.user.id
                let isPro = await MainActor.run { revenueCat.isPro }
                
                do {
                    let remainingBossAttempts = try await SupabaseManager.shared.getRemainingBossAttempts(userId: userId, isPro: isPro)
                    await MainActor.run {
                        bossAttemptsRemaining = remainingBossAttempts
                    }
                } catch {
                    print("Failed to refresh boss attempts after error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Timer Functions
    
    /// Calculate time remaining until midnight (next reset)
    private func calculateTimeUntilReset() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        // Get tomorrow at midnight
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return 0
        }
        
        return midnight.timeIntervalSince(now)
    }
    
    /// Format time interval as HH:MM:SS
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Start the countdown timer (only for Pro users with exhausted attempts)
    private func startTimer() {
        // Stop existing timer if any
        timerTask?.cancel()
        
        // Only start timer if Pro user and attempts exhausted
        guard revenueCat.isPro && bossAttemptsRemaining <= 0 else {
            return
        }
        
        // Calculate initial time
        timeUntilReset = calculateTimeUntilReset()
        
        // Start timer that updates every second
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                if Task.isCancelled { break }
                
                await MainActor.run {
                    timeUntilReset = calculateTimeUntilReset()
                    
                    // If timer reached 0, refresh attempts from database
                    if timeUntilReset <= 0 {
                        Task {
                            await loadData()
                        }
                    }
                }
            }
        }
    }
    
    /// Stop the countdown timer
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}

// MARK: - Portal Boss Card

struct PortalBossCard: View {
    let boss: PortalBoss
    let progress: PortalRaidProgress?
    let userStats: BattlerStats
    let isSelected: Bool
    let portalAttempts: Int
    let onTap: () -> Void
    
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var pulseOpacity: Double = 0.6
    
    private var rankInfo: RankInfo {
        RankService.getRankByCode(boss.rank) ?? RankService.allRanks[0]
    }
    
    private var rankColor: Color {
        rankInfo.swiftUIColor
    }
    
    private var rankTitle: String {
        return "\(boss.rank)-RANK"
    }
    
    private var estimatedAttempts: String {
        let remainingHP = progress?.remainingHp ?? boss.maxHp
        let estimate = PortalService.estimateAttemptsNeeded(
            userStats: userStats,
            bossStats: boss.battlerStats,
            remainingHP: remainingHP
        )
        if estimate.min == estimate.max {
            if estimate.min == 1 {
                return "Short"
            } else if estimate.min <= 3 {
                return "~\(estimate.min)-\(estimate.max) Attempts"
            } else {
                return "Long"
            }
        }
        return "~\(estimate.min)-\(estimate.max) Attempts"
    }
    
    private var bossRewards: (xp: Int, gold: Int) {
        PortalService.calculateBossRewards(
            bossRank: boss.rank,
            bossLevel: RankService.getBossLevelForRank(rankCode: boss.rank, seed: boss.id.hashValue)
        )
    }
    
    private var bossLevel: Int {
        RankService.getBossLevelForRank(rankCode: boss.rank, seed: boss.id.hashValue)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Background with particle effect for selected card
                if isSelected {
                    ParticleBackgroundView()
                        .opacity(0.3)
                }
                
                VStack(spacing: 0) {
                    // Top padding for content below badges
                    Spacer()
                        .frame(height: 40)
                    
                    // Boss avatar and name section
                    VStack(spacing: 0) {
                        // Avatar with animated borders
                        ZStack {
                            // Outer spinning border ring
                            Circle()
                                .stroke(rankColor.opacity(0.3), lineWidth: 1)
                                .frame(width: 108, height: 108)
                                .rotationEffect(.degrees(outerRotation))
                            
                            // Middle dashed border ring (reverse rotation)
                            Circle()
                                .stroke(rankColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(innerRotation))
                            
                            // Gradient blur background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [rankColor.opacity(0.3), Color(hex: "#1e293b").opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)
                                .blur(radius: 4)
                            
                            // Avatar with gradient border
                        ZStack {
                            if let uiImage = UIImage(named: boss.imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Circle()
                                    .fill(Color(hex: "#374151"))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 40))
                                    )
                            }
                        }
                            .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                            colors: [rankColor.opacity(0.8), rankColor.opacity(0.4), Color(hex: "#1e293b")],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: rankColor.opacity(0.5), radius: 10)
                            
                            // Level badge overlay at bottom
                            VStack {
                                Spacer()
                                Text("LV. \(bossLevel)")
                                    .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                                    .background(
                                        LinearGradient(
                                            colors: [rankColor.opacity(0.9), rankColor.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(rankColor.opacity(0.5), lineWidth: 1)
                                    )
                                    .shadow(color: rankColor.opacity(0.5), radius: 5)
                                    .offset(y: 8)
                            }
                            .frame(width: 90, height: 90)
                        }
                        .frame(height: 120)
                        .padding(.bottom, 16)
                        
                        // Boss name
                        Text(boss.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .white.opacity(0.3), radius: 5)
                            .padding(.bottom, 16)
                    
                    // Progress bar
                        VStack(spacing: 6) {
                        HStack {
                                Text("Cleared")
                                .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(rankColor.opacity(0.8))
                                    .tracking(2)
                            Spacer()
                            Text("\(Int(progress?.progressPercent ?? 0))%")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(rankColor)
                        }
                            .padding(.horizontal, 4)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "#1e293b").opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    
                                    // Progress fill with gradient
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                                colors: [rankColor.opacity(0.9), rankColor.opacity(0.7), rankColor.opacity(0.5)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat((progress?.progressPercent ?? 0) / 100.0))
                                        .shadow(color: rankColor.opacity(0.6), radius: 8)
                                        .overlay(
                                            // Shimmer effect
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.clear, Color.white.opacity(0.2), Color.clear],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .frame(width: geometry.size.width * CGFloat((progress?.progressPercent ?? 0) / 100.0))
                                        )
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                    
                    // Stats section - single row with dividers
                    HStack(spacing: 0) {
                        StatItem(icon: "⚔️", label: "ATK", value: "\(boss.statAttack)", color: Color(hex: "#FACC15"))
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.1))
                        
                        StatItem(icon: "🛡️", label: "DEF", value: "\(boss.statDefense)", color: Color(hex: "#3B82F6"))
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.1))
                        
                        StatItem(icon: "❤️", label: "HP", value: "\(boss.maxHp)", color: Color(hex: "#EF4444"))
                        
                        Divider()
                            .frame(height: 40)
                            .background(Color.white.opacity(0.1))
                        
                        StatItem(icon: "⚡", label: "SPD", value: "\(boss.statSpeed)", color: Color(hex: "#10B981"))
                    }
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    // Bottom section: Estimated effort and rewards
                    HStack {
                        // Estimated effort
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EST. EFFORT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(1.5)
                            HStack(spacing: 6) {
                                Image(systemName: estimatedEffortIcon)
                                    .font(.system(size: 14))
                                    .foregroundColor(rankColor.opacity(0.8))
                                Text(estimatedAttempts)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 1, height: 32)
                        
                        Spacer()
                        
                        // Boss rewards
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("BOSS REWARDS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(1.5)
                            HStack(spacing: 12) {
                                // XP
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#60A5FA"))
                                    Text("\(formatNumber(bossRewards.xp))")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                // Gold
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#FACC15"))
                                    Text("\(formatNumber(bossRewards.gold))")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "#FEF3C7"))
                                }
                                
                                // Item box icon
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(rankColor)
                                    .shadow(color: rankColor.opacity(0.5), radius: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(rankColor.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .background(
                    ZStack {
                        // Base background
                        Color(hex: isSelected ? "#161e31" : "#111625")
                        
                        // Gradient overlay
                        LinearGradient(
                            colors: [rankColor.opacity(0.1), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isSelected ? rankColor.opacity(pulseOpacity) : Color.white.opacity(0.05),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? rankColor.opacity(pulseOpacity * 0.4) : Color.clear,
                    radius: isSelected ? 20 : 0
                )
                
                // Top-left specialization badge - positioned at corner
                HStack(spacing: 6) {
                    Image(systemName: specializationIcon)
                        .font(.system(size: 12))
                    Text(boss.specialization.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundColor(boss.specializationColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(boss.specializationColor.opacity(0.1))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0
                    )
                    .stroke(boss.specializationColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: boss.specializationColor.opacity(0.1), radius: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
                // Top-right rank badge - positioned at corner
                Text(rankTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(rankColor)
                    .tracking(2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(rankColor.opacity(0.1))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 24
                        )
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 24
                        )
                        .stroke(rankColor.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: rankColor.opacity(0.1), radius: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Start rotation animations
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
            
            // Start pulsing animation if selected
            if isSelected {
                startPulseAnimation()
            }
        }
        .onChange(of: isSelected) { newValue in
            if newValue {
                startPulseAnimation()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    pulseOpacity = 0.6
                }
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.9
        }
    }
    
    private var specializationIcon: String {
        switch boss.specialization {
        case "Tank": return "shield.fill"
        case "Glass Cannon": return "sparkles"
        case "Speedster": return "bolt.fill"
        case "Balanced": return "equal.circle.fill"
        default: return "equal.circle.fill"
        }
    }
    
    private var estimatedEffortIcon: String {
        let remainingHP = progress?.remainingHp ?? boss.maxHp
        let estimate = PortalService.estimateAttemptsNeeded(
            userStats: userStats,
            bossStats: boss.battlerStats,
            remainingHP: remainingHP
        )
        if estimate.min <= 1 {
            return "hourglass"
        } else if estimate.min <= 3 {
            return "clock"
        } else {
            return "hourglass.bottom"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Stat Item (for new stats layout)

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "#6B7280"))
                .tracking(1.5)
            HStack(spacing: 6) {
                Text(icon)
                    .font(.system(size: 12))
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Particle Background View

struct ParticleBackgroundView: View {
    var body: some View {
        GeometryReader { geometry in
            let rows = Int(geometry.size.height / 20)
            let cols = Int(geometry.size.width / 20)
            
            ZStack {
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 1, height: 1)
                            .offset(x: CGFloat(col) * 20, y: CGFloat(row) * 20)
                    }
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Uneven Rounded Rectangle Shape (for corner badges)

struct UnevenRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat = 0
    var bottomLeadingRadius: CGFloat = 0
    var bottomTrailingRadius: CGFloat = 0
    var topTrailingRadius: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Start from top-left (after radius)
        path.move(to: CGPoint(x: topLeadingRadius, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: width - topTrailingRadius, y: 0))
        
        // Top-right corner
        if topTrailingRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: width, y: topTrailingRadius),
                control: CGPoint(x: width, y: 0)
            )
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Right edge
        path.addLine(to: CGPoint(x: width, y: height - bottomTrailingRadius))
        
        // Bottom-right corner
        if bottomTrailingRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: width - bottomTrailingRadius, y: height),
                control: CGPoint(x: width, y: height)
            )
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Bottom edge
        path.addLine(to: CGPoint(x: bottomLeadingRadius, y: height))
        
        // Bottom-left corner
        if bottomLeadingRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: 0, y: height - bottomLeadingRadius),
                control: CGPoint(x: 0, y: height)
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: topLeadingRadius))
        
        // Top-left corner
        if topLeadingRadius > 0 {
            path.addQuadCurve(
                to: CGPoint(x: topLeadingRadius, y: 0),
                control: CGPoint(x: 0, y: 0)
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        path.closeSubpath()
        return path
    }
}


