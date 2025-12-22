//
//  BattleService.swift
//  Animarc IOS
//
//  Battle logic with stat-based combat mechanics
//

import Foundation

// MARK: - Battle Performance Metrics

struct BattlePerformance {
    // User performance
    let userDamageDealt: Int
    let userDamageBlocked: Int
    let userCriticalHits: Int
    let userPerfectDodges: Int
    let userEffectiveAttack: Double  // Attack rating considering opponent's defense
    let userEffectiveDefense: Double // Defense rating considering opponent's attack
    
    // Opponent performance
    let opponentDamageDealt: Int
    let opponentDamageBlocked: Int
    let opponentCriticalHits: Int
    let opponentPerfectDodges: Int
    let opponentEffectiveAttack: Double
    let opponentEffectiveDefense: Double
    
    // Battle summary
    let totalExchanges: Int  // Number of attack exchanges that occurred
    let battleIntensity: Double  // How close the battle was (0.0 = one-sided, 1.0 = very close)
    let dominantStat: String  // Which stat was most impactful ("Attack", "Defense", "Speed", "Health")
}

// MARK: - Battler Stats

struct BattlerStats {
    let health: Int
    let attack: Int
    let defense: Int
    let speed: Int
    let level: Int
    let focusPower: Int  // Keep for display purposes
    
    // Derived stats
    var totalStats: Int {
        return attack + defense + speed + ((health - 150) / 5)
    }
}

// MARK: - Battle Result

struct BattleResult {
    let didWin: Bool
    let xpEarned: Int
    let goldEarned: Int
    let opponentName: String
    let difficultyTier: DifficultyTier
    let performance: BattlePerformance?  // Detailed breakdown of what happened
}

// MARK: - Difficulty Tier

enum DifficultyTier {
    case easy, fair, hard
    
    var goldRange: ClosedRange<Int> {
        switch self {
        case .easy: return 3...8
        case .fair: return 18...32
        case .hard: return 40...60
        }
    }
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .fair: return "Fair"
        case .hard: return "Hard"
        }
    }
}

// MARK: - Battle Service

class BattleService {
    
    // MARK: - Stat-Based Probability Calculation
    
    /// Calculate win probability using individual stats
    /// - Parameters:
    ///   - userStats: User's battle stats
    ///   - opponentStats: Opponent's battle stats
    /// - Returns: Win probability as a Double between 0.0 and 1.0
    static func calculateWinProbability(userStats: BattlerStats, opponentStats: BattlerStats) -> Double {
        // Base probability starts at 50%
        var probability = 0.5
        
        // 1. ATTACK vs DEFENSE interaction (±15% max)
        let attackDifference = userStats.attack - opponentStats.defense
        let attackModifier = Double(attackDifference) / 100.0 * 0.15
        probability += attackModifier
        
        // 2. DEFENSE vs ATTACK interaction (±15% max)
        let defenseDifference = userStats.defense - opponentStats.attack
        let defenseModifier = Double(defenseDifference) / 100.0 * 0.15
        probability += defenseModifier
        
        // 3. SPEED advantage (±10% max) - faster = better crit/dodge
        let speedDifference = userStats.speed - opponentStats.speed
        let speedModifier = Double(speedDifference) / 150.0 * 0.10
        probability += speedModifier
        
        // 4. HEALTH advantage (±10% max) - more HP = more staying power
        let healthDifference = userStats.health - opponentStats.health
        let healthModifier = Double(healthDifference) / 200.0 * 0.10
        probability += healthModifier
        
        // Cap between 15% and 85% (more dynamic range than before)
        return max(0.15, min(0.85, probability))
    }
    
    /// Legacy method for backward compatibility (converts FP to basic stats)
    static func calculateWinProbability(userFP: Int, opponentFP: Int) -> Double {
        // Convert FP to basic stats for legacy support
        let userStats = convertFPToStats(fp: userFP, level: 5)
        let opponentStats = convertFPToStats(fp: opponentFP, level: 5)
        return calculateWinProbability(userStats: userStats, opponentStats: opponentStats)
    }
    
    // MARK: - Combat Mechanics Calculations
    
    /// Calculate base damage based on attack stat
    static func calculateBaseDamage(attackStat: Int) -> Int {
        let baseDamage = 50
        let attackMultiplier = Double(attackStat) / 10.0
        return baseDamage + Int(attackMultiplier * 8)
    }
    
    /// Calculate damage reduction based on defense stat
    static func calculateDamageReduction(defenseStat: Int, incomingDamage: Int) -> Int {
        let defenseMultiplier = min(0.70, Double(defenseStat) / 150.0)  // Cap at 70% reduction
        let damageReduction = Double(incomingDamage) * defenseMultiplier
        let finalDamage = incomingDamage - Int(damageReduction)
        return max(10, finalDamage)  // Minimum 10 damage always goes through
    }
    
    /// Calculate critical hit chance based on speed stat
    static func calculateCriticalChance(speedStat: Int) -> Double {
        let baseChance = 0.10  // 10% base
        let speedBonus = Double(speedStat) / 200.0
        return min(0.40, baseChance + speedBonus)  // Cap at 40%
    }
    
    /// Calculate dodge chance based on speed stat
    static func calculateDodgeChance(speedStat: Int) -> Double {
        let baseChance = 0.05  // 5% base
        let speedBonus = Double(speedStat) / 250.0
        return min(0.30, baseChance + speedBonus)  // Cap at 30%
    }
    
    /// Calculate max HP based on health stat
    static func calculateMaxHP(healthStat: Int) -> Int {
        return healthStat * 2
    }
    
    // MARK: - Battle Performance Simulation
    
    /// Simulate what happened during the battle for performance breakdown
    /// This is called AFTER we know who won, to generate the story of the battle
    static func simulateBattlePerformance(
        userStats: BattlerStats,
        opponentStats: BattlerStats,
        didWin: Bool
    ) -> BattlePerformance {
        
        // Simulate 3-5 attack exchanges
        let numExchanges = Int.random(in: 3...5)
        
        var userTotalDamage = 0
        var userTotalBlocked = 0
        var userCrits = 0
        var userDodges = 0
        
        var opponentTotalDamage = 0
        var opponentTotalBlocked = 0
        var opponentCrits = 0
        var opponentDodges = 0
        
        // Simulate each exchange
        for _ in 0..<numExchanges {
            // User's attack
            let userBaseDamage = calculateBaseDamage(attackStat: userStats.attack)
            let userCritRoll = Double.random(in: 0...1)
            let opponentDodgeRoll = Double.random(in: 0...1)
            
            if opponentDodgeRoll < calculateDodgeChance(speedStat: opponentStats.speed) {
                // Opponent dodged
                opponentDodges += 1
            } else if userCritRoll < calculateCriticalChance(speedStat: userStats.speed) {
                // Critical hit!
                let critDamage = userBaseDamage * 2
                let finalDamage = calculateDamageReduction(defenseStat: opponentStats.defense, incomingDamage: critDamage)
                userTotalDamage += finalDamage
                opponentTotalBlocked += (critDamage - finalDamage)
                userCrits += 1
            } else {
                // Normal hit
                let finalDamage = calculateDamageReduction(defenseStat: opponentStats.defense, incomingDamage: userBaseDamage)
                userTotalDamage += finalDamage
                opponentTotalBlocked += (userBaseDamage - finalDamage)
            }
            
            // Opponent's attack
            let opponentBaseDamage = calculateBaseDamage(attackStat: opponentStats.attack)
            let opponentCritRoll = Double.random(in: 0...1)
            let userDodgeRoll = Double.random(in: 0...1)
            
            if userDodgeRoll < calculateDodgeChance(speedStat: userStats.speed) {
                // User dodged
                userDodges += 1
            } else if opponentCritRoll < calculateCriticalChance(speedStat: opponentStats.speed) {
                // Opponent critical hit
                let critDamage = opponentBaseDamage * 2
                let finalDamage = calculateDamageReduction(defenseStat: userStats.defense, incomingDamage: critDamage)
                opponentTotalDamage += finalDamage
                userTotalBlocked += (critDamage - finalDamage)
                opponentCrits += 1
            } else {
                // Normal hit
                let finalDamage = calculateDamageReduction(defenseStat: userStats.defense, incomingDamage: opponentBaseDamage)
                opponentTotalDamage += finalDamage
                userTotalBlocked += (opponentBaseDamage - finalDamage)
            }
        }
        
        // Adjust damage based on who won (winner must have dealt more damage)
        if didWin {
            // Ensure user's damage is higher than opponent's
            let multiplier = max(1.3, Double(opponentTotalDamage) / Double(max(1, userTotalDamage)) * 1.1)
            userTotalDamage = Int(Double(userTotalDamage) * multiplier)
            // Ensure user's damage is at least 10% more than opponent's
            if userTotalDamage <= opponentTotalDamage {
                userTotalDamage = Int(Double(opponentTotalDamage) * 1.1) + 1
            }
        } else {
            // Ensure opponent's damage is higher than user's
            let multiplier = max(1.3, Double(userTotalDamage) / Double(max(1, opponentTotalDamage)) * 1.1)
            opponentTotalDamage = Int(Double(opponentTotalDamage) * multiplier)
            // Ensure opponent's damage is at least 10% more than user's
            if opponentTotalDamage <= userTotalDamage {
                opponentTotalDamage = Int(Double(userTotalDamage) * 1.1) + 1
            }
        }
        
        // Calculate battle intensity (how close it was)
        let damageDifference = abs(userTotalDamage - opponentTotalDamage)
        let totalDamage = userTotalDamage + opponentTotalDamage
        let intensity = 1.0 - (Double(damageDifference) / Double(max(1, totalDamage)))
        
        // Determine dominant stat
        let dominantStat = determineDominantStat(
            userStats: userStats,
            opponentStats: opponentStats,
            userCrits: userCrits,
            userDodges: userDodges,
            userBlocked: userTotalBlocked
        )
        
        // Calculate effective ratings
        let userEffectiveAttack = Double(userStats.attack) / Double(max(1, opponentStats.defense)) * 100
        let userEffectiveDefense = Double(userStats.defense) / Double(max(1, opponentStats.attack)) * 100
        let opponentEffectiveAttack = Double(opponentStats.attack) / Double(max(1, userStats.defense)) * 100
        let opponentEffectiveDefense = Double(opponentStats.defense) / Double(max(1, userStats.attack)) * 100
        
        return BattlePerformance(
            userDamageDealt: userTotalDamage,
            userDamageBlocked: userTotalBlocked,
            userCriticalHits: userCrits,
            userPerfectDodges: userDodges,
            userEffectiveAttack: userEffectiveAttack,
            userEffectiveDefense: userEffectiveDefense,
            opponentDamageDealt: opponentTotalDamage,
            opponentDamageBlocked: opponentTotalBlocked,
            opponentCriticalHits: opponentCrits,
            opponentPerfectDodges: opponentDodges,
            opponentEffectiveAttack: opponentEffectiveAttack,
            opponentEffectiveDefense: opponentEffectiveDefense,
            totalExchanges: numExchanges,
            battleIntensity: intensity,
            dominantStat: dominantStat
        )
    }
    
    /// Determine which stat had the most impact on the battle
    static func determineDominantStat(
        userStats: BattlerStats,
        opponentStats: BattlerStats,
        userCrits: Int,
        userDodges: Int,
        userBlocked: Int
    ) -> String {
        var statScores: [String: Double] = [:]
        
        // Attack importance: based on attack difference
        let attackDiff = abs(userStats.attack - opponentStats.attack)
        statScores["Attack"] = Double(attackDiff) * 1.5
        
        // Defense importance: based on damage blocked
        statScores["Defense"] = Double(userBlocked) * 0.8
        
        // Speed importance: based on crits and dodges
        statScores["Speed"] = Double(userCrits + userDodges) * 50.0
        
        // Health importance: based on health difference
        let healthDiff = abs(userStats.health - opponentStats.health)
        statScores["Health"] = Double(healthDiff) * 0.5
        
        // Return the stat with highest score
        return statScores.max(by: { $0.value < $1.value })?.key ?? "Attack"
    }
    
    // MARK: - Difficulty Determination
    
    /// Determine difficulty tier based on total stats comparison
    static func determineDifficulty(userStats: BattlerStats, opponentStats: BattlerStats) -> DifficultyTier {
        let statsDifference = userStats.totalStats - opponentStats.totalStats
        
        if statsDifference >= 30 {
            return .easy  // User has 30+ more stat points
        } else if statsDifference <= -30 {
            return .hard  // Opponent has 30+ more stat points
        } else {
            return .fair  // Within ±30
        }
    }
    
    /// Legacy method for backward compatibility
    static func determineDifficulty(userFP: Int, opponentFP: Int) -> DifficultyTier {
        let fpDifference = userFP - opponentFP
        
        if fpDifference >= 200 {
            return .easy
        } else if fpDifference <= -200 {
            return .hard
        } else {
            return .fair
        }
    }
    
    // MARK: - Battle Simulation
    
    /// Simulate a battle using stat-based mechanics
    static func simulateBattle(userStats: BattlerStats, opponentStats: BattlerStats) -> (didWin: Bool, difficulty: DifficultyTier, performance: BattlePerformance) {
        let difficulty = determineDifficulty(userStats: userStats, opponentStats: opponentStats)
        let winProbability = calculateWinProbability(userStats: userStats, opponentStats: opponentStats)
        
        // Random roll between 0.0 and 1.0
        let randomRoll = Double.random(in: 0.0...1.0)
        let didWin = randomRoll < winProbability
        
        // Simulate what happened during the battle
        let performance = simulateBattlePerformance(
            userStats: userStats,
            opponentStats: opponentStats,
            didWin: didWin
        )
        
        return (didWin: didWin, difficulty: difficulty, performance: performance)
    }
    
    /// Legacy method for backward compatibility
    static func simulateBattle(userFP: Int, opponentFP: Int) -> (didWin: Bool, difficulty: DifficultyTier) {
        let userStats = convertFPToStats(fp: userFP, level: 5)
        let opponentStats = convertFPToStats(fp: opponentFP, level: 5)
        let result = simulateBattle(userStats: userStats, opponentStats: opponentStats)
        return (didWin: result.didWin, difficulty: result.difficulty)
    }
    
    /// Calculate exact gold reward deterministically based on opponent ID
    /// This ensures the same opponent always gives the same gold amount
    /// - Parameters:
    ///   - opponentId: Unique identifier for the opponent
    ///   - difficulty: Difficulty tier of the opponent
    /// - Returns: Exact gold amount within the difficulty tier range
    static func calculateExactGold(opponentId: String, difficulty: DifficultyTier) -> Int {
        // Use opponent ID as seed for deterministic calculation
        var hasher = Hasher()
        hasher.combine(opponentId)
        let seed = hasher.finalize()
        
        // Create a pseudo-random number generator seeded with opponent ID
        var generator = SeededRandomNumberGenerator(seed: UInt64(abs(seed)))
        
        // Generate gold within the difficulty tier range
        return Int.random(in: difficulty.goldRange, using: &generator)
    }
    
    // MARK: - Rewards Calculation
    
    /// Calculate rewards with performance bonuses
    static func calculateRewards(
        didWin: Bool,
        difficulty: DifficultyTier,
        performance: BattlePerformance?,
        exactGold: Int? = nil
    ) -> (xp: Int, gold: Int) {
        let baseXP: Int
        let baseGold: Int
        
        if didWin {
            baseXP = 50
            baseGold = exactGold ?? Int.random(in: difficulty.goldRange)
        } else {
            baseXP = 10
            baseGold = 0
        }
        
        // Apply performance bonuses (if available)
        var finalXP = baseXP
        var finalGold = baseGold
        
        if let perf = performance, didWin {
            var xpBonus = 0.0
            var goldBonus = 0.0
            
            // Bonus for critical hits
            if perf.userCriticalHits >= 2 {
                xpBonus += 0.10  // +10%
                goldBonus += 0.15  // +15%
            }
            
            // Bonus for dodges
            if perf.userPerfectDodges >= 2 {
                xpBonus += 0.10
                goldBonus += 0.15
            }
            
            // Bonus for dealing significantly more damage
            if Double(perf.userDamageDealt) > Double(perf.opponentDamageDealt) * 1.5 {
                xpBonus += 0.15  // +15% for dominant victory
                goldBonus += 0.20  // +20%
            }
            
            finalXP += Int(Double(baseXP) * xpBonus)
            finalGold += Int(Double(baseGold) * goldBonus)
        }
        
        return (xp: finalXP, gold: finalGold)
    }
    
    /// Legacy method for backward compatibility
    static func calculateRewards(didWin: Bool, difficulty: DifficultyTier, exactGold: Int? = nil) -> (xp: Int, gold: Int) {
        return calculateRewards(didWin: didWin, difficulty: difficulty, performance: nil, exactGold: exactGold)
    }
    
    // MARK: - Complete Battle Execution
    
    /// Execute a complete battle with stat-based mechanics
    static func executeBattle(
        userStats: BattlerStats,
        opponentStats: BattlerStats,
        opponentName: String,
        opponentId: String? = nil,
        exactGold: Int? = nil
    ) -> BattleResult {
        let (didWin, difficulty, performance) = simulateBattle(userStats: userStats, opponentStats: opponentStats)
        
        // Calculate exact gold if not provided
        let goldAmount: Int
        if let exact = exactGold {
            goldAmount = exact
        } else if let id = opponentId {
            goldAmount = calculateExactGold(opponentId: id, difficulty: difficulty)
        } else {
            goldAmount = Int.random(in: difficulty.goldRange)
        }
        
        let (xp, gold) = calculateRewards(
            didWin: didWin,
            difficulty: difficulty,
            performance: performance,
            exactGold: didWin ? goldAmount : nil
        )
        
        return BattleResult(
            didWin: didWin,
            xpEarned: xp,
            goldEarned: gold,
            opponentName: opponentName,
            difficultyTier: difficulty,
            performance: performance
        )
    }
    
    /// Legacy method for backward compatibility
    static func executeBattle(
        userFP: Int,
        opponentFP: Int,
        opponentName: String,
        opponentId: String? = nil,
        exactGold: Int? = nil
    ) -> BattleResult {
        let userStats = convertFPToStats(fp: userFP, level: 5)
        let opponentStats = convertFPToStats(fp: opponentFP, level: 5)
        return executeBattle(
            userStats: userStats,
            opponentStats: opponentStats,
            opponentName: opponentName,
            opponentId: opponentId,
            exactGold: exactGold
        )
    }
    
    // MARK: - Helper Methods
    
    /// Convert Focus Power to basic stats (for backward compatibility)
    private static func convertFPToStats(fp: Int, level: Int) -> BattlerStats {
        let baseFP = 1000
        let extraPoints = max(0, fp - baseFP)
        
        // Distribute extra FP evenly across stats
        let pointsPerStat = extraPoints / 4
        
        return BattlerStats(
            health: 150 + (pointsPerStat * 5),  // Health uses 5x multiplier
            attack: 10 + pointsPerStat,
            defense: 10 + pointsPerStat,
            speed: 10 + pointsPerStat,
            level: level,
            focusPower: fp
        )
    }
}

// MARK: - Seeded Random Number Generator

/// A simple seeded random number generator for deterministic gold calculation
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = (state &* 1103515245 &+ 12345) & 0x7fffffff
        return state
    }
}

