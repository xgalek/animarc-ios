//
//  FindOpponentView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

// MARK: - Custom Shape for Badge (rounded bottom-left only)

struct BottomLeftRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        // Line to top-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Line to bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Arc to bottom-left (rounded corner)
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        // Line back to start
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}

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
    let imageName: String // Local asset name for opponent image
    let statHealth: Int
    let statAttack: Int
    let statDefense: Int
    let statSpeed: Int
    let statSpecialization: String  // "Tank", "Glass Cannon", "Speedster", "Balanced"
    
    init(id: String, name: String, level: Int, rank: String, rankColor: Color, successRate: Int, focusPower: Int, exactGoldReward: Int, imageName: String, statHealth: Int, statAttack: Int, statDefense: Int, statSpeed: Int, statSpecialization: String) {
        self.id = id
        self.name = name
        self.level = level
        self.rank = rank
        self.rankColor = rankColor
        self.successRate = successRate
        self.focusPower = focusPower
        self.exactGoldReward = exactGoldReward
        self.imageName = imageName
        self.statHealth = statHealth
        self.statAttack = statAttack
        self.statDefense = statDefense
        self.statSpeed = statSpeed
        self.statSpecialization = statSpecialization
    }
}

// MARK: - Find Opponent View

struct FindOpponentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var selectedOpponent: Opponent? = nil
    @State private var contentAppeared = false
    @State private var battleResultData: BattleResultData? = nil
    @State private var showBattleAnimation = false
    @State private var pendingBattleData: (opponent: Opponent, userStats: BattlerStats, opponentStats: BattlerStats)? = nil
    
    // Static list of 45 AI opponent names (matching 45 available images)
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
        "EmeraldFlow"
    ]
    
    // Map opponent index to image asset name
    // Returns the asset name for the opponent image based on sequential mapping
    // Note: "Opponents/" prefix is required because the asset folder has namespace enabled
    private static func getOpponentImageName(index: Int) -> String {
        // Map each opponent index (0-44) to the corresponding image number
        let imageNumbers = [2, 6, 9, 10, 16, 17, 19, 20, 23, 24, 25, 26, 28, 33, 35, 36, 40, 42, 46, 47, 55, 60, 64, 65, 71, 72, 73, 77, 81, 89, 102, 105, 187, 189, 190, 192, 194, 195, 214, 222, 223, 226, 229, 279, 280]
        
        // Ensure index is within bounds (use modulo for safety)
        let safeIndex = index % imageNumbers.count
        return "Opponents/_Stylized Cute Warrior Character (\(imageNumbers[safeIndex]))"
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
    
    /// Generate specialized stats based on opponent name and level
    /// - Parameters:
    ///   - opponentName: Name of the opponent (used as seed)
    ///   - level: Opponent level
    ///   - generator: Seeded random number generator
    /// - Returns: Tuple with (health, attack, defense, speed, specialization)
    private func generateSpecializedStats(opponentName: String, level: Int, generator: inout SeededRandomNumberGenerator) -> (health: Int, attack: Int, defense: Int, speed: Int, specialization: String) {
        // Calculate total stat budget based on level
        // Base stats: 150 health, 10 attack, 10 defense, 10 speed = 180 total
        // Each level adds ~15 stat points distributed
        let baseStats = 180
        let levelBonus = level * 15
        let totalStatBudget = baseStats + levelBonus
        
        // Determine specialization based on opponent name hash (deterministic)
        var nameHasher = Hasher()
        nameHasher.combine(opponentName)
        let nameHash = abs(nameHasher.finalize())
        let specializationIndex = nameHash % 4
        
        let specialization: String
        let health: Int
        let attack: Int
        let defense: Int
        let speed: Int
        
        switch specializationIndex {
        case 0: // Tank: High Health + Defense, lower Attack + Speed
            specialization = "Tank"
            health = 150 + Int(Double(levelBonus) * 0.45) + Int.random(in: 0...10, using: &generator)
            defense = 10 + Int(Double(levelBonus) * 0.35) + Int.random(in: 0...8, using: &generator)
            attack = 10 + Int(Double(levelBonus) * 0.10) + Int.random(in: 0...5, using: &generator)
            speed = 10 + Int(Double(levelBonus) * 0.10) + Int.random(in: 0...5, using: &generator)
            
        case 1: // Glass Cannon: High Attack, very low Defense + Health, moderate Speed
            specialization = "Glass Cannon"
            attack = 10 + Int(Double(levelBonus) * 0.50) + Int.random(in: 0...10, using: &generator)
            speed = 10 + Int(Double(levelBonus) * 0.25) + Int.random(in: 0...8, using: &generator)
            health = 150 + Int(Double(levelBonus) * 0.15) + Int.random(in: 0...5, using: &generator)
            defense = 10 + Int(Double(levelBonus) * 0.10) + Int.random(in: 0...3, using: &generator)
            
        case 2: // Speedster: High Speed + Attack, lower Defense, moderate Health
            specialization = "Speedster"
            speed = 10 + Int(Double(levelBonus) * 0.40) + Int.random(in: 0...10, using: &generator)
            attack = 10 + Int(Double(levelBonus) * 0.30) + Int.random(in: 0...8, using: &generator)
            health = 150 + Int(Double(levelBonus) * 0.20) + Int.random(in: 0...5, using: &generator)
            defense = 10 + Int(Double(levelBonus) * 0.10) + Int.random(in: 0...5, using: &generator)
            
        default: // Balanced: Even distribution
            specialization = "Balanced"
            let perStat = levelBonus / 4
            health = 150 + perStat + Int.random(in: 0...5, using: &generator)
            attack = 10 + perStat + Int.random(in: 0...5, using: &generator)
            defense = 10 + perStat + Int.random(in: 0...5, using: &generator)
            speed = 10 + perStat + Int.random(in: 0...5, using: &generator)
        }
        
        return (health: health, attack: attack, defense: defense, speed: speed, specialization: specialization)
    }
    
    /// Generate default opponents when user progress is not available
    private func generateDefaultOpponents() -> [Opponent] {
        // Randomly select 5 unique opponent names
        let selectedNames = Array(Self.opponentNames.shuffled().prefix(5))
        
        // Default user stats (level 1 new user)
        let defaultUserStats = BattlerStats(
            health: 150,
            attack: 10,
            defense: 10,
            speed: 10,
            level: 1,
            focusPower: 1000
        )
        
        return selectedNames.enumerated().map { index, name in
            // Find the index of this name in the original array
            let nameIndex = Self.opponentNames.firstIndex(of: name) ?? index
            let imageName = Self.getOpponentImageName(index: nameIndex)
            
            // Generate base stats for specialization (for build type only)
            var nameHasher = Hasher()
            nameHasher.combine(name)
            var statGenerator = SeededRandomNumberGenerator(seed: UInt64(abs(nameHasher.finalize())))
            let baseStats = generateSpecializedStats(opponentName: name, level: 1, generator: &statGenerator)
            
            // Fixed stat values for fallback opponents
            let stats: (health: Int, attack: Int, defense: Int, speed: Int, specialization: String)
            let level: Int
            let focusPower: Int
            
            switch index {
            case 0: // Easy
                stats = (health: 90, attack: 6, defense: 6, speed: 6, specialization: baseStats.specialization)
                level = 1
                focusPower = 800
            case 1, 2, 3: // Fair
                stats = (health: 150, attack: 10, defense: 10, speed: 10, specialization: baseStats.specialization)
                level = 1
                focusPower = 1000
            case 4: // Hard
                stats = (health: 220, attack: 15, defense: 15, speed: 15, specialization: baseStats.specialization)
                level = 2
                focusPower = 1500
            default:
                stats = (health: 150, attack: 10, defense: 10, speed: 10, specialization: baseStats.specialization)
                level = 1
                focusPower = 1000
            }
            
            let rankInfo = RankService.getRankForLevel(level)
            
            // Create opponent stats for calculation
            let opponentStats = BattlerStats(
                health: stats.health,
                attack: stats.attack,
                defense: stats.defense,
                speed: stats.speed,
                level: level,
                focusPower: focusPower
            )
            
            // Calculate difficulty and win probability using stat-based system
            let difficulty = BattleService.determineDifficulty(userStats: defaultUserStats, opponentStats: opponentStats)
            let exactGold = BattleService.calculateExactGold(opponentId: name, difficulty: difficulty)
            let winProbability = BattleService.calculateWinProbability(userStats: defaultUserStats, opponentStats: opponentStats)
            let successRate = Int(winProbability * 100)
            
            return Opponent(
                id: name,
                name: name,
                level: level,
                rank: rankInfo.code,
                rankColor: rankInfo.swiftUIColor,
                successRate: successRate,
                focusPower: focusPower,
                exactGoldReward: exactGold,
                imageName: imageName,
                statHealth: stats.health,
                statAttack: stats.attack,
                statDefense: stats.defense,
                statSpeed: stats.speed,
                statSpecialization: stats.specialization
            )
        }
    }
    
    /// Generate dynamic opponents based on player stats
    /// - Parameters:
    ///   - userLevel: Player's current level
    ///   - userFocusPower: Player's current focus power
    /// - Returns: Array of 5 opponents with varying difficulty (1 Easy, 3 Fair, 1 Hard)
    private func generateDynamicOpponents(userLevel: Int, userFocusPower: Int) -> [Opponent] {
        // Use user stats to create a deterministic seed for selecting opponents
        // This ensures the same opponents appear for the same user state
        var hasher = Hasher()
        hasher.combine(userLevel)
        hasher.combine(userFocusPower)
        let selectionSeed = UInt64(abs(hasher.finalize()))
        var selectionGenerator = SeededRandomNumberGenerator(seed: selectionSeed)
        
        // Randomly select 5 unique opponent names based on user state
        let shuffledNames = Self.opponentNames.shuffled(using: &selectionGenerator)
        let selectedNames = Array(shuffledNames.prefix(5))
        
        return selectedNames.enumerated().map { index, name in
            // Find the index of this name in the original array
            let nameIndex = Self.opponentNames.firstIndex(of: name) ?? index
            let imageName = Self.getOpponentImageName(index: nameIndex)
            
            // Generate deterministic random values based on opponent name
            let seed = generateSeed(from: name, userLevel: userLevel, userFocusPower: userFocusPower)
            var generator = SeededRandomNumberGenerator(seed: seed)
            
            // Get user stats first - we'll generate opponents relative to these
            let userStats = calculateUserStats()
            
            // Generate base stats for specialization (we'll use this for build type only)
            let baseStats = generateSpecializedStats(opponentName: name, level: userLevel, generator: &generator)
            
            // Generate opponent stats as percentages of user stats
            let stats: (health: Int, attack: Int, defense: Int, speed: Int, specialization: String)
            let opponentLevel: Int
            let opponentFocusPower: Int
            
            switch index {
            case 0: // Easy - 60% of user stats
                stats = (
                    health: max(80, Int(Double(userStats.health) * 0.60)),
                    attack: max(3, Int(Double(userStats.attack) * 0.60)),
                    defense: max(3, Int(Double(userStats.defense) * 0.60)),
                    speed: max(3, Int(Double(userStats.speed) * 0.60)),
                    specialization: baseStats.specialization
                )
                // Display values (cosmetic)
                opponentLevel = max(1, userLevel - 3)
                opponentFocusPower = max(800, Int(Double(userFocusPower) * 0.60))
                
            case 1, 2, 3: // Fair - 85-115% of user stats
                let variance = Double.random(in: 0.85...1.15, using: &generator)
                stats = (
                    health: max(100, Int(Double(userStats.health) * variance)),
                    attack: max(5, Int(Double(userStats.attack) * variance)),
                    defense: max(5, Int(Double(userStats.defense) * variance)),
                    speed: max(5, Int(Double(userStats.speed) * variance)),
                    specialization: baseStats.specialization
                )
                // Display values (cosmetic)
                opponentLevel = max(1, Int(Double(userLevel) * variance))
                opponentFocusPower = max(1000, Int(Double(userFocusPower) * variance))
                
            case 4: // Hard - 145-165% of user stats
                let multiplier = Double.random(in: 1.45...1.65, using: &generator)
                stats = (
                    health: Int(Double(userStats.health) * multiplier),
                    attack: Int(Double(userStats.attack) * multiplier),
                    defense: Int(Double(userStats.defense) * multiplier),
                    speed: Int(Double(userStats.speed) * multiplier),
                    specialization: baseStats.specialization
                )
                // Display values (cosmetic)
                opponentLevel = Int(Double(userLevel) * multiplier)
                opponentFocusPower = Int(Double(userFocusPower) * multiplier)
                
            default:
                stats = (
                    health: userStats.health,
                    attack: userStats.attack,
                    defense: userStats.defense,
                    speed: userStats.speed,
                    specialization: baseStats.specialization
                )
                opponentLevel = userLevel
                opponentFocusPower = userFocusPower
            }
            
            // Get rank based on generated level (for display)
            let rankInfo = RankService.getRankForLevel(opponentLevel)
            
            // Create BattlerStats for win probability calculation
            let opponentStats = BattlerStats(
                health: stats.health,
                attack: stats.attack,
                defense: stats.defense,
                speed: stats.speed,
                level: opponentLevel,
                focusPower: opponentFocusPower
            )
            
            // Calculate user stats for comparison (already calculated above, but need BattlerStats format)
            guard let progress = progressManager.userProgress else {
                // Fallback: Use stat-based calculation with default user stats
                let defaultUserStats = BattlerStats(
                    health: 150,
                    attack: 10,
                    defense: 10,
                    speed: 10,
                    level: 1,
                    focusPower: 1000
                )
                let difficulty = BattleService.determineDifficulty(userStats: defaultUserStats, opponentStats: opponentStats)
                let exactGold = BattleService.calculateExactGold(opponentId: name, difficulty: difficulty)
                let winProbability = BattleService.calculateWinProbability(userStats: defaultUserStats, opponentStats: opponentStats)
                let successRate = Int(winProbability * 100)
                
                return Opponent(
                    id: name,
                    name: name,
                    level: opponentLevel,
                    rank: rankInfo.code,
                    rankColor: rankInfo.swiftUIColor,
                    successRate: successRate,
                    focusPower: opponentFocusPower,
                    exactGoldReward: exactGold,
                    imageName: imageName,
                    statHealth: stats.health,
                    statAttack: stats.attack,
                    statDefense: stats.defense,
                    statSpeed: stats.speed,
                    statSpecialization: stats.specialization
                )
            }
            
            // User stats already calculated above, create BattlerStats format
            let userBattlerStats = BattlerStats(
                health: progress.statHealth,
                attack: progress.statAttack,
                defense: progress.statDefense,
                speed: progress.statSpeed,
                level: progress.currentLevel,
                focusPower: userFocusPower
            )
            
            // Calculate difficulty tier and gold reward using stat-based system
            let difficulty = BattleService.determineDifficulty(userStats: userBattlerStats, opponentStats: opponentStats)
            let exactGold = BattleService.calculateExactGold(opponentId: name, difficulty: difficulty)
            
            // Calculate success rate using stat-based probability
            let winProbability = BattleService.calculateWinProbability(userStats: userBattlerStats, opponentStats: opponentStats)
            let successRate = Int(winProbability * 100)
            
            return Opponent(
                id: name,
                name: name,
                level: opponentLevel,
                rank: rankInfo.code,
                rankColor: rankInfo.swiftUIColor,
                successRate: successRate,
                focusPower: opponentFocusPower,
                exactGoldReward: exactGold,
                imageName: imageName,
                statHealth: stats.health,
                statAttack: stats.attack,
                statDefense: stats.defense,
                statSpeed: stats.speed,
                statSpecialization: stats.specialization
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
            
            // Battle animation overlay (on top of everything)
            if showBattleAnimation, let battleData = pendingBattleData {
                BattleAnimationView(
                    userAvatar: "ProfileIcon/profile image",
                    opponentAvatar: battleData.opponent.imageName,
                    userStats: battleData.userStats,
                    opponentStats: battleData.opponentStats,
                    onComplete: { calculatedResult in
                        // Animation complete, now calculate full battle result with proper rewards
                        let opponent = battleData.opponent
                        
                        // Execute full battle with stat-based mechanics
                        let result = BattleService.executeBattle(
                            userStats: battleData.userStats,
                            opponentStats: battleData.opponentStats,
                            opponentName: opponent.name,
                            opponentId: opponent.id,
                            exactGold: opponent.exactGoldReward
                        )
                        
                        // Update backend with battle rewards
                        Task {
                            await updateBattleRewards(result: result)
                        }
                        
                        // Dismiss animation and show result
                        showBattleAnimation = false
                        
                        // Small delay to ensure smooth transition
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            battleResultData = BattleResultData(result: result, opponent: opponent)
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(999)
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
            
            // Pre-select the first opponent (easy win)
            if opponents.count >= 1 {
                selectedOpponent = opponents[0]
            }
        }
    }
    
    private func calculateUserFocusPower() -> Int {
        guard let progress = progressManager.userProgress else { return 1000 }
        // For now, use empty equipped items array
        // In the future, pass inventory from CharacterView
        return UserProgress.calculateFocusPower(progress: progress, equippedItems: [])
    }
    
    /// Create BattlerStats from user's progress
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
        
        let fp = calculateUserFocusPower()
        return BattlerStats(
            health: progress.statHealth,
            attack: progress.statAttack,
            defense: progress.statDefense,
            speed: progress.statSpeed,
            level: progress.currentLevel,
            focusPower: fp
        )
    }
    
    /// Create BattlerStats from opponent
    private func createOpponentStats(from opponent: Opponent) -> BattlerStats {
        return BattlerStats(
            health: opponent.statHealth,
            attack: opponent.statAttack,
            defense: opponent.statDefense,
            speed: opponent.statSpeed,
            level: opponent.level,
            focusPower: opponent.focusPower
        )
    }
    
    private func startBattle() {
        guard let opponent = selectedOpponent else { return }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Create stats for battle
        let userStats = calculateUserStats()
        let opponentStats = createOpponentStats(from: opponent)
        
        // Store battle data and show animation
        pendingBattleData = (opponent: opponent, userStats: userStats, opponentStats: opponentStats)
        
        // Trigger battle animation
        showBattleAnimation = true
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
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    // Top section: Avatar, name, stats
                    HStack(alignment: .top, spacing: 16) {
                        // Avatar - use UIImage for reliable asset loading
                        Group {
                            if let uiImage = UIImage(named: opponent.imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Circle()
                                    .fill(Color(hex: "#374151"))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 24))
                                    )
                            }
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(opponent.rankColor.opacity(0.6), lineWidth: 2)
                        )
                        
                        // Name and rank
                        VStack(alignment: .leading, spacing: 4) {
                            Text(opponent.name)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
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
                    .padding(.top, 10) // Extra top padding for badge
                
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
                
                // Build type badge - positioned absolutely in top-right corner
                HStack(spacing: 4) {
                    Image(systemName: badgeIcon(for: opponent.statSpecialization))
                        .font(.system(size: 10, weight: .bold))
                    
                    Text(badgeText(for: opponent.statSpecialization))
                        .font(.system(size: 9.6, weight: .bold))
                        .tracking(3)
                }
                .foregroundColor(badgeTextColor(for: opponent.statSpecialization))
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(badgeBackgroundColor(for: opponent.statSpecialization))
                .overlay(
                    // Left and bottom borders only
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                // Left border
                                Rectangle()
                                    .fill(badgeBorderColor(for: opponent.statSpecialization))
                                    .frame(width: 1)
                                    .frame(maxHeight: .infinity)
                                
                                Spacer()
                            }
                            
                            Spacer()
                            
                            // Bottom border
                            Rectangle()
                                .fill(badgeBorderColor(for: opponent.statSpecialization))
                                .frame(height: 1)
                                .frame(maxWidth: .infinity)
                        }
                    }
                )
                .clipShape(BottomLeftRoundedRectangle(cornerRadius: 12))
                .offset(x: 0, y: 0)
                .zIndex(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function to format badge text
    private func badgeText(for specialization: String) -> String {
        return specialization.uppercased().replacingOccurrences(of: " ", with: "")
    }
    
    // Helper function to get badge icon
    private func badgeIcon(for specialization: String) -> String {
        switch specialization {
        case "Tank":
            return "shield.fill"
        case "Glass Cannon":
            return "flame.fill"
        case "Speedster":
            return "bolt.fill"
        case "Balanced":
            return "equal.circle.fill"
        default:
            return "equal.circle.fill"
        }
    }
    
    // Helper function to get badge background color (semi-transparent)
    private func badgeBackgroundColor(for specialization: String) -> Color {
        switch specialization {
        case "Tank":
            return Color(hex: "#3B82F6").opacity(0.1)
        case "Glass Cannon":
            return Color(hex: "#EF4444").opacity(0.1)
        case "Speedster":
            return Color(hex: "#F59E0B").opacity(0.1)
        case "Balanced":
            return Color(hex: "#10B981").opacity(0.1)
        default:
            return Color(hex: "#10B981").opacity(0.1)
        }
    }
    
    // Helper function to get badge text color
    private func badgeTextColor(for specialization: String) -> Color {
        switch specialization {
        case "Tank":
            return Color(hex: "#3B82F6")
        case "Glass Cannon":
            return Color(hex: "#EF4444")
        case "Speedster":
            return Color(hex: "#F59E0B")
        case "Balanced":
            return Color(hex: "#10B981")
        default:
            return Color(hex: "#10B981")
        }
    }
    
    // Helper function to get badge border color
    private func badgeBorderColor(for specialization: String) -> Color {
        switch specialization {
        case "Tank":
            return Color(hex: "#3B82F6").opacity(0.2)
        case "Glass Cannon":
            return Color(hex: "#EF4444").opacity(0.2)
        case "Speedster":
            return Color(hex: "#F59E0B").opacity(0.2)
        case "Balanced":
            return Color(hex: "#10B981").opacity(0.2)
        default:
            return Color(hex: "#10B981").opacity(0.2)
        }
    }
}

// MARK: - Preview

#Preview {
    FindOpponentView()
}

