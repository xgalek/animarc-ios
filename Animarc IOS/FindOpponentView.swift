//
//  FindOpponentView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

// MARK: - Battle Result Data (for navigation)

struct BattleResultData: Identifiable {
    let id = UUID()
    let result: BattleResult
    let opponent: Opponent
}

// MARK: - Opponent Model

struct Opponent: Identifiable {
    let id: String
    let name: String
    let level: Int
    let rank: String
    let rankColor: Color
    let successRate: Int
    let focusPower: Int
    let exactGoldReward: Int // Exact gold amount that will be awarded (if win)
    let avatarUrl: String
    
    init(id: String, name: String, level: Int, rank: String, rankColor: Color, successRate: Int, focusPower: Int, exactGoldReward: Int, avatarUrl: String) {
        self.id = id
        self.name = name
        self.level = level
        self.rank = rank
        self.rankColor = rankColor
        self.successRate = successRate
        self.focusPower = focusPower
        self.exactGoldReward = exactGoldReward
        self.avatarUrl = avatarUrl
    }
}

// MARK: - Find Opponent View

struct FindOpponentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var selectedOpponent: Opponent? = nil
    @State private var contentAppeared = false
    @State private var battleResultData: BattleResultData? = nil
    
    // Static list of 50 AI opponent names
    private static let opponentNames: [String] = [
        "ShadowHunter",
        "FocusMaster",
        "ZenWarrior99",
        "DeepWorkKing",
        "StudyNinja",
        "MidnightGrinder",
        "FlowStateGod",
        "HustleHero",
        "IronWilliam",
        "TaskSlayer",
        "PixelMonk",
        "CodeSamurai",
        "BookWorm",
        "FocusPhantom",
        "GrindMachine",
        "AlphaLearner",
        "SilentScholar",
        "RushWarrior",
        "ThinkTank",
        "ChillHustle",
        "NeonFocus",
        "QuantumMind",
        "SteelDiscipline",
        "EchoHunter",
        "PeakPerformer",
        "VoidWalker",
        "CrystalClear",
        "ZenMaster",
        "FlashFocus",
        "IceBreaker",
        "ThunderStudy",
        "WaveRider",
        "MysticGrind",
        "PhoenixRise",
        "ShadowStep",
        "LightSpeed",
        "FrostBite",
        "BlazePath",
        "StormChaser",
        "SilverBullet",
        "GoldRush",
        "DiamondMind",
        "RubyFocus",
        "SapphireWill",
        "EmeraldFlow",
        "OnyxWarrior",
        "PearlWisdom",
        "TopazHunter",
        "AmethystDream",
        "ObsidianGrit"
    ]
    
    // Default avatar URL for opponents (using a placeholder avatar service)
    private static let defaultAvatarUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuA1TQgK-rvEfSKL7lv7jYaCrt_ncnOrmRSfI_Tz9fZhM9jpOsWPBiMUa8nrBR79av49E47Ni3hCALedDpN5s-w_BeDm27aLXQM7khxzwQEnL5GwInSrcN6-CMYeRgP0ZDBiSNRpLvywpGDUWgceakMCq4Fn80UTgqQEfvwDYQH0YHu3_7faBEoXDfBeE7ZAc-RlHJ2hSUt4d9TrzKtM5MdNQDszBoH8veiGW05B1HPei06USkeeaOFo905ZX52dlpnCMjOZfI2dKHh5"
    
    // Generate deterministic avatar URL based on opponent name
    private func generateAvatarUrl(for name: String) -> String {
        // Use a deterministic approach: hash the name to select from a pool of avatar URLs
        // For now, we'll use the default avatar URL for all opponents
        // In the future, this could be expanded to use different avatars based on name hash
        return Self.defaultAvatarUrl
    }
    
    // Dynamically generated opponents based on player stats
    private var opponents: [Opponent] {
        // Calculate user's stats for opponent generation
        guard let progress = progressManager.userProgress else {
            return generateDefaultOpponents()
        }
        
        let userLevel = progressManager.currentLevel
        let userFP = calculateUserFocusPower()
        
        return generateDynamicOpponents(
            userLevel: userLevel,
            userFocusPower: userFP
        )
    }
    
    /// Generate default opponents when user progress is not available
    private func generateDefaultOpponents() -> [Opponent] {
        // Randomly select 3 unique opponent names
        let selectedNames = Array(Self.opponentNames.shuffled().prefix(3))
        
        return selectedNames.enumerated().map { index, name in
            let level = [5, 3, 7][index]
            let rankInfo = RankService.getRankForLevel(level)
            let focusPower = [1251, 2423, 1850][index]
            let difficulty = BattleService.determineDifficulty(userFP: 1000, opponentFP: focusPower)
            // Use name as ID for deterministic gold calculation
            let exactGold = BattleService.calculateExactGold(opponentId: name, difficulty: difficulty)
            
            return Opponent(
                id: name, // Use name as unique ID
                name: name,
                level: level,
                rank: rankInfo.code,
                rankColor: rankInfo.swiftUIColor,
                successRate: [98, 55, 63][index],
                focusPower: focusPower,
                exactGoldReward: exactGold,
                avatarUrl: generateAvatarUrl(for: name)
            )
        }
    }
    
    /// Generate dynamic opponents based on player stats
    /// - Parameters:
    ///   - userLevel: Player's current level
    ///   - userFocusPower: Player's current focus power
    /// - Returns: Array of 3 opponents with varying difficulty
    private func generateDynamicOpponents(userLevel: Int, userFocusPower: Int) -> [Opponent] {
        // Use user stats to create a deterministic seed for selecting opponents
        // This ensures the same opponents appear for the same user state
        var hasher = Hasher()
        hasher.combine(userLevel)
        hasher.combine(userFocusPower)
        let selectionSeed = UInt64(abs(hasher.finalize()))
        var selectionGenerator = SeededRandomNumberGenerator(seed: selectionSeed)
        
        // Randomly select 3 unique opponent names based on user state
        let shuffledNames = Self.opponentNames.shuffled(using: &selectionGenerator)
        let selectedNames = Array(shuffledNames.prefix(3))
        
        return selectedNames.enumerated().map { index, name in
            // Generate deterministic random values based on opponent name
            let seed = generateSeed(from: name, userLevel: userLevel, userFocusPower: userFocusPower)
            var generator = SeededRandomNumberGenerator(seed: seed)
            
            let (opponentLevel, opponentFocusPower): (Int, Int)
            
            switch index {
            case 0: // Opponent 1: Easy (weaker than player)
                let levelOffset = Int.random(in: 1...3, using: &generator)
                let fpOffset = Int.random(in: 200...300, using: &generator)
                opponentLevel = max(1, userLevel - levelOffset)
                opponentFocusPower = max(1000, userFocusPower - fpOffset)
                
            case 1: // Opponent 2: Fair (similar to player)
                let levelOffset = Int.random(in: -2...2, using: &generator)
                let fpOffset = Int.random(in: -150...150, using: &generator)
                opponentLevel = max(1, userLevel + levelOffset)
                opponentFocusPower = max(1000, userFocusPower + fpOffset)
                
            case 2: // Opponent 3: Hard (stronger than player)
                let levelOffset = Int.random(in: 1...4, using: &generator)
                let fpOffset = Int.random(in: 200...350, using: &generator)
                opponentLevel = max(1, userLevel + levelOffset)
                opponentFocusPower = max(1000, userFocusPower + fpOffset)
                
            default:
                opponentLevel = userLevel
                opponentFocusPower = userFocusPower
            }
            
            // Get rank based on generated level
            let rankInfo = RankService.getRankForLevel(opponentLevel)
            
            // Calculate difficulty tier and gold reward
            let difficulty = BattleService.determineDifficulty(userFP: userFocusPower, opponentFP: opponentFocusPower)
            let exactGold = BattleService.calculateExactGold(opponentId: name, difficulty: difficulty)
            
            // Calculate success rate based on focus power difference
            let winProbability = BattleService.calculateWinProbability(userFP: userFocusPower, opponentFP: opponentFocusPower)
            let successRate = Int(winProbability * 100)
            
            return Opponent(
                id: name, // Use name as unique ID
                name: name,
                level: opponentLevel,
                rank: rankInfo.code,
                rankColor: rankInfo.swiftUIColor,
                successRate: successRate,
                focusPower: opponentFocusPower,
                exactGoldReward: exactGold,
                avatarUrl: generateAvatarUrl(for: name)
            )
        }
    }
    
    /// Generate a deterministic seed from opponent ID and player stats
    /// This ensures the same opponent always has the same stats for a given player state
    private func generateSeed(from opponentId: String, userLevel: Int, userFocusPower: Int) -> UInt64 {
        var hasher = Hasher()
        // Combine opponent ID multiple times with different multipliers to ensure unique seeds per opponent
        hasher.combine(opponentId)
        hasher.combine(userLevel)
        hasher.combine(userFocusPower)
        // Add opponent index to ensure different seeds for different opponents
        if let opponentIndex = Int(opponentId) {
            hasher.combine(opponentIndex * 7919) // Large prime multiplier
        }
        return UInt64(abs(hasher.finalize()))
    }
    
    var body: some View {
        ZStack {
            // Background - matching dark theme
            Color(hex: "#191919")
                .ignoresSafeArea()
            
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
                    
                    Text("Find Opponent")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .background(Color(hex: "#191919").opacity(0.95))
                
                // Scrollable opponent list
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(opponents) { opponent in
                            OpponentCard(
                                opponent: opponent,
                                userFocusPower: calculateUserFocusPower(),
                                isSelected: selectedOpponent?.id == opponent.id,
                                onTap: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    selectedOpponent = opponent
                                }
                            )
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                    .delay(Double(opponents.firstIndex(where: { $0.id == opponent.id }) ?? 0) * 0.1),
                                value: contentAppeared
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120) // Extra padding for fixed button
                }
                
                Spacer()
            }
            
            // Fixed bottom button
            VStack {
                Spacer()
                
                Button(action: {
                    startBattle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Start Battle")
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
                .disabled(selectedOpponent == nil)
                .opacity(selectedOpponent == nil ? 0.6 : 1.0)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $battleResultData) { data in
            BattleResultView(
                battleResult: data.result,
                opponent: data.opponent,
                onBattleAgain: {
                    // Dismiss battle result, stay on opponent selection
                    battleResultData = nil
                },
                onReturnHome: {
                    // Dismiss both battle result and opponent selection, return to CharacterView
                    battleResultData = nil
                    dismiss()
                }
            )
            .environmentObject(progressManager)
        }
        .onAppear {
            // Trigger entrance animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
            
            // Pre-select the middle opponent (matching HTML design)
            if opponents.count >= 2 {
                selectedOpponent = opponents[1]
            }
        }
    }
    
    private func calculateUserFocusPower() -> Int {
        guard let progress = progressManager.userProgress else { return 1000 }
        // For now, use empty equipped items array
        // In the future, pass inventory from CharacterView
        return UserProgress.calculateFocusPower(progress: progress, equippedItems: [])
    }
    
    private func startBattle() {
        guard let opponent = selectedOpponent else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Calculate battle outcome using BattleService
        let userFP = calculateUserFocusPower()
        let result = BattleService.executeBattle(
            userFP: userFP,
            opponentFP: opponent.focusPower,
            opponentName: opponent.name,
            opponentId: opponent.id,
            exactGold: opponent.exactGoldReward
        )
        
        // Update backend with battle rewards
        Task {
            await updateBattleRewards(result: result)
        }
        
        // Set battle result data to trigger fullScreenCover
        battleResultData = BattleResultData(result: result, opponent: opponent)
    }
    
    /// Update user's gold and XP in the database after battle
    private func updateBattleRewards(result: BattleResult) async {
        do {
            // Get current user ID
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                print("Battle rewards: Not authenticated")
                ErrorManager.shared.showError("Failed to save battle rewards: Not authenticated")
                return
            }
            let userId = session.user.id
            
            // Store old level before update for level-up detection
            let oldLevel = progressManager.currentLevel
            
            // Update gold and XP in database
            let updatedProgress = try await SupabaseManager.shared.updateGoldAndXP(
                userId: userId,
                goldToAdd: result.goldEarned,
                xpToAdd: result.xpEarned
            )
            
            print("Battle rewards saved: +\(result.goldEarned) gold, +\(result.xpEarned) XP")
            
            // Update local progress manager state
            await MainActor.run {
                progressManager.userProgress = updatedProgress
                
                // Check for level up and set pending rewards
                let newLevel = updatedProgress.currentLevel
                if newLevel > oldLevel {
                    progressManager.pendingLevelUp = (oldLevel: oldLevel, newLevel: newLevel)
                    
                    // Check for rank up
                    if let rankUp = RankService.checkForRankUp(oldLevel: oldLevel, newLevel: newLevel) {
                        progressManager.pendingRankUp = (oldRank: rankUp.oldRank, newRank: rankUp.newRank)
                    }
                }
            }
            
        } catch {
            print("Failed to update battle rewards: \(error)")
            ErrorManager.shared.showError("Battle completed, but failed to save rewards. Pull down to refresh.")
        }
    }
}

// MARK: - Opponent Card Component

struct OpponentCard: View {
    let opponent: Opponent
    let userFocusPower: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    private var difficultyTier: DifficultyTier {
        BattleService.determineDifficulty(userFP: userFocusPower, opponentFP: opponent.focusPower)
    }
    
    private var goldDisplayText: String {
        return "\(opponent.exactGoldReward)"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Top section: Avatar, name, stats
                HStack(alignment: .top, spacing: 16) {
                    // Avatar
                    AsyncImage(url: URL(string: opponent.avatarUrl)) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(Color(hex: "#374151"))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 64, height: 64)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color(hex: "#374151"))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(opponent.rankColor.opacity(0.6), lineWidth: 2)
                    )
                    
                    // Name and rank
                    VStack(alignment: .leading, spacing: 4) {
                        Text(opponent.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("LV. \(opponent.level)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            Text("\(opponent.rank)-RANK")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(opponent.rankColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Success rate
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(opponent.successRate)%")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(Color(hex: "#22C55E"))
                        
                        Text("WIN CHANCE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .tracking(1)
                    }
                }
                .padding(16)
                
                // Bottom section: Stats box
                HStack(spacing: 0) {
                    // Focus Power
                    HStack(spacing: 12) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#F59E0B"))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FOCUS POWER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .tracking(1)
                            
                            Text("\(opponent.focusPower)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Divider
                    Rectangle()
                        .fill(Color(hex: "#374151").opacity(0.5))
                        .frame(width: 1, height: 32)
                    
                    Spacer()
                    
                    // Rewards
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("REWARDS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .tracking(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#FACC15"))
                            
                            Text("\(goldDisplayText)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#F59E0B"))
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "#0F1623"))
                .cornerRadius(16)
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
                radius: isSelected ? 15 : 0,
                x: 0,
                y: 0
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    FindOpponentView()
}

