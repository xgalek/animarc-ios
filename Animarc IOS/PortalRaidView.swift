//
//  PortalRaidView.swift
//  Animarc IOS
//
//  Portal raid system - map-based boss progression
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
    
    // Boss detail sheet
    @State private var selectedBoss: PortalBoss? = nil
    @State private var showBossDetail = false
    
    // Battle flow
    @State private var raidResultData: RaidResultData? = nil
    @State private var showBattleAnimation = false
    @State private var pendingRaidData: (boss: PortalBoss, progress: PortalRaidProgress, userStats: BattlerStats, bossStats: BattlerStats)? = nil
    
    // Map data
    @State private var mapBosses: [PortalBoss] = []
    @State private var completedBossIds: Set<UUID> = []
    @State private var bossProgress: [UUID: PortalRaidProgress] = [:]
    @State private var portalAttempts: Int = 50
    @State private var bossAttemptsRemaining: Int = 1
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var showPaywall = false
    
    // Timer for Pro users countdown
    @State private var timeUntilReset: TimeInterval = 0
    @State private var timerTask: Task<Void, Never>? = nil
    
    var body: some View {
        ZStack {
            if let error = errorMessage {
                // Error state
                ZStack {
                    Color(hex: "#0B0E14").ignoresSafeArea()
                    VStack(spacing: 16) {
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button("Retry") {
                            Task { await loadData() }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "#F59E0B"))
                        .cornerRadius(8)
                    }
                }
            } else {
                ZStack {
                    Color(hex: "#0B0E14").ignoresSafeArea()
                    
                    // Map header + content
                    VStack(spacing: 0) {
                        mapHeader
                        
                        if mapBosses.isEmpty && isLoading {
                            Spacer()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(Color(hex: "#F59E0B"))
                                Text("Opening portals...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        } else {
                            PortalRaidMapView(
                                bosses: mapBosses,
                                completedIds: completedBossIds,
                                bossProgress: bossProgress,
                                bossAttemptsRemaining: bossAttemptsRemaining,
                                onBossTapped: { boss in
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    selectedBoss = boss
                                    showBossDetail = true
                                }
                            )
                        }
                    }
                    
                    // Battle animation overlay
                    if showBattleAnimation, let raidData = pendingRaidData {
                        BattleAnimationView(
                            userAvatar: "ProfileIcon/profile image",
                            opponentAvatar: raidData.boss.imageName,
                            userStats: raidData.userStats,
                            opponentStats: raidData.bossStats,
                            onComplete: { _ in
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
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showBossDetail) {
            if let boss = selectedBoss {
                let isCurrentBoss = !completedBossIds.contains(boss.id) &&
                    boss.id == PortalService.currentBoss(from: mapBosses, completedIds: completedBossIds)?.id
                
                BossDetailView(
                    boss: boss,
                    progress: bossProgress[boss.id],
                    userStats: calculateUserStats(),
                    isCurrentBoss: isCurrentBoss,
                    bossAttemptsRemaining: bossAttemptsRemaining,
                    onAttack: {
                        showBossDetail = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            startRaid(boss: boss)
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
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
                    
                    Task {
                        await loadData()
                        await progressManager.refreshProgress()
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
        .onDisappear {
            stopTimer()
        }
        .onChange(of: bossAttemptsRemaining) { oldValue, newValue in
            if revenueCat.isPro && newValue <= 0 {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onChange(of: revenueCat.isPro) { _, _ in
            Task { await loadData() }
        }
        .toast(errorManager: errorManager)
    }
    
    // MARK: - Map Header
    
    private var mapHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
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
            
            VStack(alignment: .trailing, spacing: 2) {
                if isLoading && mapBosses.isEmpty {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(Color(hex: "#F59E0B"))
                        .frame(width: 20, height: 20)
                } else {
                    Text("\(bossAttemptsRemaining)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(bossAttemptsRemaining > 0 ? Color(hex: "#F59E0B") : Color(hex: "#DC2626"))
                }
                Text("DAILY BOSS\nATTEMPTS")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(0.3)
                    .multilineTextAlignment(.trailing)
            }
            .frame(width: 70)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(hex: "#0B0E14").opacity(0.95))
    }
    
    // MARK: - Data Loading
    
    private func loadData() async {
        if mapBosses.isEmpty {
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
            
            guard let progress = progressManager.userProgress else {
                await MainActor.run {
                    errorMessage = "User progress not loaded"
                    isLoading = false
                }
                return
            }
            
            let isPro = await MainActor.run { revenueCat.isPro }
            
            // Fetch in parallel
            let fetchedAttempts = try await SupabaseManager.shared.checkAndResetDailyAttempts(userId: userId)
            let remainingBossAttempts = try await SupabaseManager.shared.getRemainingBossAttempts(userId: userId, isPro: isPro)
            let allUserProgress = try await SupabaseManager.shared.fetchPortalProgress(userId: userId)
            let completedIds = Set(allUserProgress.filter { $0.completed }.map { $0.portalBossId })
            
            // Find highest completed map_order to determine window
            let allBossesForWindow = try await SupabaseManager.shared.fetchAllPortalBosses()
            let highestCompletedOrder = allBossesForWindow
                .filter { completedIds.contains($0.id) }
                .map { $0.mapOrder }
                .max() ?? 0
            
            // Fetch windowed bosses for the map
            let bosses = try await SupabaseManager.shared.fetchMapBosses(
                completedOrderMax: highestCompletedOrder,
                aheadCount: 8
            )
            
            // Build progress map, create entries for the current boss if needed
            var progressMap: [UUID: PortalRaidProgress] = [:]
            let existingProgressMap = Dictionary(
                grouping: allUserProgress.filter { !$0.completed },
                by: { $0.portalBossId }
            )
            
            if let currentBoss = PortalService.currentBoss(from: bosses, completedIds: completedIds) {
                if let existing = existingProgressMap[currentBoss.id]?.first {
                    progressMap[currentBoss.id] = existing
                } else {
                    let maxHp = PortalService.calculateBossHP(
                        rank: currentBoss.rank,
                        specialization: currentBoss.specialization,
                        level: RankService.getRankForLevel(progress.currentLevel).minLevel
                    )
                    let newProgress = try await SupabaseManager.shared.createPortalProgress(
                        userId: userId,
                        bossId: currentBoss.id,
                        maxHp: maxHp
                    )
                    progressMap[currentBoss.id] = newProgress
                }
            }
            
            // Include progress for any weakened (in-progress) bosses too
            for boss in bosses {
                if progressMap[boss.id] == nil, let existing = existingProgressMap[boss.id]?.first {
                    progressMap[boss.id] = existing
                }
            }
            
            await MainActor.run {
                mapBosses = bosses
                completedBossIds = completedIds
                bossProgress = progressMap
                portalAttempts = fetchedAttempts
                bossAttemptsRemaining = remainingBossAttempts
                isLoading = false
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
    
    private func startRaid(boss: PortalBoss) {
        guard let progress = bossProgress[boss.id] else { return }
        
        Task {
            guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
            let userId = session.user.id
            let isPro = await MainActor.run { revenueCat.isPro }
            
            do {
                let freshPortalAttempts = try await SupabaseManager.shared.getPortalAttempts(userId: userId)
                await MainActor.run {
                    portalAttempts = freshPortalAttempts
                }
                guard freshPortalAttempts > 0 else { return }
            } catch {
                print("Failed to fetch portal attempts: \(error)")
                return
            }
            
            do {
                let canAttempt = try await SupabaseManager.shared.canAttemptBoss(userId: userId, isPro: isPro)
                
                if !canAttempt {
                    await MainActor.run {
                        if isPro {
                            errorManager.showInfo("Your character is resting. Ready for another fight tomorrow!")
                        } else {
                            showPaywall = true
                        }
                    }
                    return
                }
            } catch {
                print("Failed to check boss attempts: \(error)")
                return
            }
            
            await MainActor.run {
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
            guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
            let userId = session.user.id
            
            portalAttempts = try await SupabaseManager.shared.consumePortalAttempt(userId: userId)
            
            let updatedLimits = try await SupabaseManager.shared.incrementBossAttempts(userId: userId)
            let isPro = await MainActor.run { revenueCat.isPro }
            let maxAttempts = isPro ? 3 : 1
            await MainActor.run {
                bossAttemptsRemaining = max(0, maxAttempts - updatedLimits.bossAttemptsUsed)
            }
            
            let result = PortalService.executeRaidAttempt(
                userStats: raidData.userStats,
                bossStats: raidData.bossStats,
                currentProgress: raidData.progress
            )
            
            var updatedProgress = raidData.progress
            updatedProgress.applyDamage(result.damageDealt)
            
            let savedProgress = try await SupabaseManager.shared.updatePortalProgress(
                userId: userId,
                progressId: updatedProgress.id,
                newDamage: updatedProgress.currentDamage,
                newPercent: updatedProgress.progressPercent
            )
            
            var rewards: (xp: Int, gold: Int)? = nil
            if result.bossDefeated {
                _ = try await SupabaseManager.shared.completePortalBoss(userId: userId, progressId: savedProgress.id)
                
                let bossRewards = PortalService.calculateBossRewards(
                    bossRank: raidData.boss.rank,
                    bossLevel: raidData.boss.bossLevel
                )
                
                let oldLevel = progressManager.userProgress?.currentLevel ?? 1
                
                let updatedUserProgress = try await SupabaseManager.shared.updateGoldAndXP(
                    userId: userId,
                    goldToAdd: bossRewards.gold,
                    xpToAdd: bossRewards.xp
                )
                
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
                }
                
                await MainActor.run {
                    progressManager.userProgress = updatedUserProgress
                    
                    let newLevel = updatedUserProgress.currentLevel
                    if newLevel > oldLevel {
                        if let rankUp = RankService.checkForRankUp(oldLevel: oldLevel, newLevel: newLevel) {
                            progressManager.pendingRankUp = (oldRank: rankUp.oldRank, newRank: rankUp.newRank)
                        }
                        progressManager.pendingLevelUp = (oldLevel: oldLevel, newLevel: newLevel)
                    }
                }
                
                rewards = bossRewards
                
                await loadData()
            } else {
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
            
            Task {
                guard let session = try? await SupabaseManager.shared.client.auth.session else { return }
                let userId = session.user.id
                let isPro = await MainActor.run { revenueCat.isPro }
                
                do {
                    let remaining = try await SupabaseManager.shared.getRemainingBossAttempts(userId: userId, isPro: isPro)
                    await MainActor.run { bossAttemptsRemaining = remaining }
                } catch {
                    print("Failed to refresh boss attempts after error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Timer Functions
    
    private func calculateTimeUntilReset() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return 0
        }
        return midnight.timeIntervalSince(now)
    }
    
    private func formatTimeRemaining(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func startTimer() {
        timerTask?.cancel()
        guard revenueCat.isPro && bossAttemptsRemaining <= 0 else { return }
        
        timeUntilReset = calculateTimeUntilReset()
        
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                
                await MainActor.run {
                    timeUntilReset = calculateTimeUntilReset()
                    if timeUntilReset <= 0 {
                        Task { await loadData() }
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timeUntilReset = 0
    }
}

// MARK: - Stat Item

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

// MARK: - Uneven Rounded Rectangle Shape

struct UnevenRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat = 0
    var bottomLeadingRadius: CGFloat = 0
    var bottomTrailingRadius: CGFloat = 0
    var topTrailingRadius: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: topLeadingRadius, y: 0))
        path.addLine(to: CGPoint(x: width - topTrailingRadius, y: 0))
        
        if topTrailingRadius > 0 {
            path.addQuadCurve(to: CGPoint(x: width, y: topTrailingRadius), control: CGPoint(x: width, y: 0))
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        path.addLine(to: CGPoint(x: width, y: height - bottomTrailingRadius))
        
        if bottomTrailingRadius > 0 {
            path.addQuadCurve(to: CGPoint(x: width - bottomTrailingRadius, y: height), control: CGPoint(x: width, y: height))
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        path.addLine(to: CGPoint(x: bottomLeadingRadius, y: height))
        
        if bottomLeadingRadius > 0 {
            path.addQuadCurve(to: CGPoint(x: 0, y: height - bottomLeadingRadius), control: CGPoint(x: 0, y: height))
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        path.addLine(to: CGPoint(x: 0, y: topLeadingRadius))
        
        if topLeadingRadius > 0 {
            path.addQuadCurve(to: CGPoint(x: topLeadingRadius, y: 0), control: CGPoint(x: 0, y: 0))
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        path.closeSubpath()
        return path
    }
}
