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
    
    @State private var selectedBoss: PortalBoss? = nil
    @State private var contentAppeared = false
    @State private var raidResultData: RaidResultData? = nil
    @State private var showBattleAnimation = false
    @State private var pendingRaidData: (boss: PortalBoss, progress: PortalRaidProgress, userStats: BattlerStats, bossStats: BattlerStats)? = nil
    
    @State private var availableBosses: [PortalBoss] = []
    @State private var bossProgress: [UUID: PortalRaidProgress] = [:]
    @State private var portalAttempts: Int = 50
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
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
                        
                        // Portal attempts counter with minimal loading indicator
                        VStack(alignment: .trailing, spacing: 2) {
                            if isLoading && availableBosses.isEmpty {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .tint(Color(hex: "#F59E0B"))
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("\(portalAttempts)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(Color(hex: "#F59E0B"))
                            }
                            Text("ATTEMPTS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(1)
                        }
                        .frame(width: 60)
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
                                        portalAttempts: portalAttempts,
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
                        startRaid()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .bold))
                            Text("ATTACK BOSS")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
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
                    .disabled(selectedBoss == nil || portalAttempts <= 0)
                    .opacity((selectedBoss == nil || portalAttempts <= 0) ? 0.6 : 1.0)
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
                }
            )
            .environmentObject(progressManager)
        }
        .task {
            await loadData()
        }
        .onAppear {
            // Content appearance is now handled in loadData() after data loads
            // This ensures smooth fade-in after data is ready
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        // Show cached data immediately if available (optimistic UI)
        if !cachedBosses.isEmpty {
            await MainActor.run {
                availableBosses = cachedBosses
                bossProgress = cachedProgress
                portalAttempts = cachedAttempts
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
            async let attemptsTask = SupabaseManager.shared.checkAndResetDailyAttempts(userId: userId)
            async let userProgressTask = SupabaseManager.shared.fetchPortalProgress(userId: userId)
            async let bossesTask = SupabaseManager.shared.fetchAvailablePortalBosses(userRank: progress.currentRank)
            
            // Wait for all parallel calls to complete
            let (fetchedAttempts, allUserProgress, allBosses) = try await (attemptsTask, userProgressTask, bossesTask)
            
            // Process results
            let completedBossIds = Set(allUserProgress.filter { $0.completed }.map { $0.portalBossId })
            let bossesToSelectFrom = allBosses.filter { !completedBossIds.contains($0.id) }
            
            let selectedBosses = PortalService.generateAvailablePortals(
                userLevel: progress.currentLevel,
                userRank: progress.currentRank,
                allBosses: bossesToSelectFrom
            )
            
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
              let progress = bossProgress[boss.id],
              portalAttempts > 0 else {
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let userStats = calculateUserStats()
        let bossStats = boss.battlerStats
        
        pendingRaidData = (boss: boss, progress: progress, userStats: userStats, bossStats: bossStats)
        showBattleAnimation = true
    }
    
    private func executeRaidAttempt(raidData: (boss: PortalBoss, progress: PortalRaidProgress, userStats: BattlerStats, bossStats: BattlerStats)) async {
        do {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                return
            }
            let userId = session.user.id
            
            // Consume attempt
            portalAttempts = try await SupabaseManager.shared.consumePortalAttempt(userId: userId)
            
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
                progressId: updatedProgress.id,
                newDamage: updatedProgress.currentDamage,
                newPercent: updatedProgress.progressPercent
            )
            
            // If boss defeated, mark as completed and award rewards
            var rewards: (xp: Int, gold: Int)? = nil
            if result.bossDefeated {
                _ = try await SupabaseManager.shared.completePortalBoss(progressId: savedProgress.id)
                
                let bossRewards = PortalService.calculateBossRewards(
                    bossRank: raidData.boss.rank,
                    bossLevel: RankService.getRankForLevel(progressManager.currentLevel).minLevel
                )
                
                // Update user progress with rewards
                let updatedUserProgress = try await SupabaseManager.shared.updateGoldAndXP(
                    userId: userId,
                    goldToAdd: bossRewards.gold,
                    xpToAdd: bossRewards.xp
                )
                
                await MainActor.run {
                    progressManager.userProgress = updatedUserProgress
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
        }
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
    
    private var estimatedAttempts: String {
        let remainingHP = progress?.remainingHp ?? boss.maxHp
        let estimate = PortalService.estimateAttemptsNeeded(
            userStats: userStats,
            bossStats: boss.battlerStats,
            remainingHP: remainingHP
        )
        return "~\(estimate.min)-\(estimate.max) Sessions"
    }
    
    private var bossRewards: (xp: Int, gold: Int) {
        PortalService.calculateBossRewards(
            bossRank: boss.rank,
            bossLevel: RankService.getRankForLevel(userStats.level).minLevel
        )
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    // Top section: Specialization badge and rank
                    HStack {
                        // Specialization badge (top-left)
                        HStack(spacing: 4) {
                            Image(systemName: specializationIcon)
                                .font(.system(size: 10, weight: .bold))
                            Text(boss.specialization.uppercased())
                                .font(.system(size: 9.6, weight: .bold))
                                .tracking(3)
                        }
                        .foregroundColor(boss.specializationColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(boss.specializationColor.opacity(0.1))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        // Rank title (top-right)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(boss.rank)-RANK ABYSS")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#FACC15"))
                            Text("Recommended")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // Boss avatar and name
                    VStack(spacing: 12) {
                        ZStack {
                            // Avatar with dashed border
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
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "#EF4444"), Color(hex: "#F97316")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                                )
                        )
                        
                        // Level badge
                        Text("LV. \(RankService.getRankForLevel(userStats.level).minLevel)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#EF4444"))
                            .cornerRadius(6)
                        
                        // Boss name
                        Text(boss.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    
                    // Progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("CORRUPTION CLEARED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(1)
                            Spacer()
                            Text("\(Int(progress?.progressPercent ?? 0))%")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#FACC15"))
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "#374151").opacity(0.3))
                                
                                // Progress fill
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#EF4444"), Color(hex: "#F97316")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat((progress?.progressPercent ?? 0) / 100.0))
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Stats grid
                    HStack(spacing: 12) {
                        StatBadge(icon: "⚔️", label: "ATK", value: "\(boss.statAttack)", color: Color(hex: "#FACC15"))
                        StatBadge(icon: "🛡️", label: "DEF", value: "\(boss.statDefense)", color: Color(hex: "#3B82F6"))
                        StatBadge(icon: "❤️", label: "HP", value: "\(boss.maxHp)", color: Color(hex: "#EF4444"))
                        StatBadge(icon: "⚡", label: "SPD", value: "\(boss.statSpeed)", color: Color(hex: "#10B981"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Bottom section: Estimated effort and rewards
                    HStack {
                        // Estimated effort
                        VStack(alignment: .leading, spacing: 4) {
                            Text("EST. EFFORT")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(1)
                            HStack(spacing: 4) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#FACC15"))
                                Text(estimatedAttempts)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        // Boss rewards
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("BOSS REWARDS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(1)
                            HStack(spacing: 8) {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#80D8FF"))
                                    Text("\(formatNumber(bossRewards.xp))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#FACC15"))
                                    Text("\(formatNumber(bossRewards.gold))")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "#131B29"))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isSelected ? Color(hex: "#F59E0B").opacity(0.8) : Color(hex: "#374151").opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .shadow(
                    color: isSelected ? Color(hex: "#F59E0B").opacity(0.3) : Color.clear,
                    radius: isSelected ? 15 : 0
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var specializationIcon: String {
        switch boss.specialization {
        case "Tank": return "shield.fill"
        case "Glass Cannon": return "flame.fill"
        case "Speedster": return "bolt.fill"
        case "Balanced": return "equal.circle.fill"
        default: return "equal.circle.fill"
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 16))
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .tracking(1)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "#0F1623"))
        .cornerRadius(8)
    }
}

