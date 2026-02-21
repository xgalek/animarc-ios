//
//  PortalService.swift
//  Animarc IOS
//
//  Portal raid system business logic
//

import Foundation

class PortalService {
    
    // MARK: - Boss HP Calculation
    
    /// Calculate boss max HP based on rank and specialization
    /// - Parameters:
    ///   - rank: Boss rank (E, D, C, B, A, S)
    ///   - specialization: Boss specialization (Tank, Balanced, Speedster, Glass Cannon)
    ///   - level: Boss level (for future scaling)
    /// - Returns: Max HP value
    static func calculateBossHP(rank: String, specialization: String, level: Int = 1) -> Int {
        let baseHP: Int
        switch rank {
        case "E": baseHP = 300
        case "D": baseHP = 500
        case "C": baseHP = 800
        case "B": baseHP = 1200
        case "A": baseHP = 1800
        case "S": baseHP = 2500
        default: baseHP = 300
        }
        
        let multiplier: Double
        switch specialization {
        case "Tank": multiplier = 1.5
        case "Balanced": multiplier = 1.0
        case "Speedster": multiplier = 0.7
        case "Glass Cannon": multiplier = 0.6
        default: multiplier = 1.0
        }
        
        return Int(Double(baseHP) * multiplier)
    }
    
    // MARK: - Raid Attempt Execution
    
    /// Execute one raid attempt against a boss
    /// - Parameters:
    ///   - userStats: User's battle stats
    ///   - bossStats: Boss's battle stats
    ///   - currentProgress: Current progress on this boss
    /// - Returns: RaidAttemptResult with damage dealt and completion status
    static func executeRaidAttempt(
        userStats: BattlerStats,
        bossStats: BattlerStats,
        currentProgress: PortalRaidProgress
    ) -> RaidAttemptResult {
        // Simulate full battle
        var userHP = userStats.health * 2
        var bossHP = currentProgress.remainingHp
        var totalDamageDealt = 0
        
        let exchanges = Int.random(in: 3...5)
        
        for _ in 0..<exchanges {
            // User attacks boss
            let damage = BattleService.calculateBaseDamage(attackStat: userStats.attack)
            let critRoll = Double.random(in: 0...1)
            
            let finalDamage: Int
            if critRoll < BattleService.calculateCriticalChance(speedStat: userStats.speed) {
                let critDamage = damage * 2
                finalDamage = BattleService.calculateDamageReduction(
                    defenseStat: bossStats.defense,
                    incomingDamage: critDamage
                )
            } else {
                finalDamage = BattleService.calculateDamageReduction(
                    defenseStat: bossStats.defense,
                    incomingDamage: damage
                )
            }
            
            bossHP -= finalDamage
            totalDamageDealt += finalDamage
            
            if bossHP <= 0 { break }
            
            // Boss attacks user (for feedback, user can't die in portal raids)
            let bossDamage = BattleService.calculateBaseDamage(attackStat: bossStats.attack)
            let reducedDamage = BattleService.calculateDamageReduction(
                defenseStat: userStats.defense,
                incomingDamage: bossDamage
            )
            userHP -= reducedDamage
            
            if userHP <= 0 { break }
        }
        
        let newTotalDamage = currentProgress.currentDamage + totalDamageDealt
        let newPercent = min(100.0, (Double(newTotalDamage) / Double(currentProgress.maxHp)) * 100)
        let bossDefeated = newTotalDamage >= currentProgress.maxHp
        
        return RaidAttemptResult(
            damageDealt: totalDamageDealt,
            newTotalDamage: newTotalDamage,
            newProgressPercent: newPercent,
            bossDefeated: bossDefeated,
            userSurvived: userHP > 0
        )
    }
    
    // MARK: - Map Progression
    
    /// Determine the current boss (first non-completed boss in map order)
    static func currentBoss(from bosses: [PortalBoss], completedIds: Set<UUID>) -> PortalBoss? {
        return bosses.sorted(by: { $0.mapOrder < $1.mapOrder })
            .first { !completedIds.contains($0.id) }
    }
    
    /// Categorize bosses into defeated / current / locked for map display
    static func categorizeBosses(
        bosses: [PortalBoss],
        completedIds: Set<UUID>
    ) -> (defeated: [PortalBoss], current: PortalBoss?, locked: [PortalBoss]) {
        let sorted = bosses.sorted { $0.mapOrder < $1.mapOrder }
        var defeated: [PortalBoss] = []
        var current: PortalBoss? = nil
        var locked: [PortalBoss] = []
        
        for boss in sorted {
            if completedIds.contains(boss.id) {
                defeated.append(boss)
            } else if current == nil {
                current = boss
            } else {
                locked.append(boss)
            }
        }
        
        return (defeated, current, locked)
    }
    
    /// Get next rank after current rank
    static func getNextRank(_ currentRank: String) -> String? {
        let ranks = ["E", "D", "C", "B", "A", "S", "SS", "SSS"]
        guard let index = ranks.firstIndex(of: currentRank), index < ranks.count - 1 else {
            return nil
        }
        return ranks[index + 1]
    }
    
    // MARK: - Estimated Attempts
    
    /// Estimate how many attempts needed to defeat boss
    /// - Parameters:
    ///   - userStats: User's battle stats
    ///   - bossStats: Boss's battle stats
    ///   - remainingHP: Boss's remaining HP
    /// - Returns: Estimated attempts range (min-max)
    static func estimateAttemptsNeeded(
        userStats: BattlerStats,
        bossStats: BattlerStats,
        remainingHP: Int
    ) -> (min: Int, max: Int) {
        // Calculate average damage per attempt
        let baseDamage = BattleService.calculateBaseDamage(attackStat: userStats.attack)
        let reducedDamage = BattleService.calculateDamageReduction(
            defenseStat: bossStats.defense,
            incomingDamage: baseDamage
        )
        
        // Average exchanges per attempt: 4
        // Average crit chance: 15%
        let avgDamagePerExchange = Double(reducedDamage) * 0.85 + Double(reducedDamage * 2) * 0.15
        let avgDamagePerAttempt = avgDamagePerExchange * 4.0
        
        let attemptsNeeded = Double(remainingHP) / avgDamagePerAttempt
        let minAttempts = max(1, Int(ceil(attemptsNeeded * 0.8)))
        let maxAttempts = max(minAttempts + 1, Int(ceil(attemptsNeeded * 1.2)))
        
        return (min: minAttempts, max: maxAttempts)
    }
    
    // MARK: - Rewards Calculation
    
    /// Calculate rewards for defeating a boss
    /// - Parameters:
    ///   - bossRank: Boss's rank
    ///   - bossLevel: Boss's level
    /// - Returns: Tuple of (XP, Gold)
    static func calculateBossRewards(bossRank: String, bossLevel: Int) -> (xp: Int, gold: Int) {
        // Base rewards per rank
        let baseXP: Int
        let baseGold: Int
        
        switch bossRank {
        case "E":
            baseXP = 100
            baseGold = 50
        case "D":
            baseXP = 200
            baseGold = 100
        case "C":
            baseXP = 350
            baseGold = 200
        case "B":
            baseXP = 500
            baseGold = 350
        case "A":
            baseXP = 750
            baseGold = 500
        case "S":
            baseXP = 1000
            baseGold = 750
        default:
            baseXP = 100
            baseGold = 50
        }
        
        // Level multiplier (slight scaling)
        let levelMultiplier = 1.0 + (Double(bossLevel) * 0.02)
        
        return (
            xp: Int(Double(baseXP) * levelMultiplier),
            gold: Int(Double(baseGold) * levelMultiplier)
        )
    }
}




