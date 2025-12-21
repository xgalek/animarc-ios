//
//  BattleService.swift
//  Animarc IOS
//
//  Battle logic and rewards calculation
//

import Foundation

// MARK: - Battle Result

struct BattleResult {
    let didWin: Bool
    let xpEarned: Int
    let goldEarned: Int
    let opponentName: String
    let difficultyTier: DifficultyTier
}

// MARK: - Difficulty Tier

enum DifficultyTier {
    case easy, fair, hard
    
    var goldRange: ClosedRange<Int> {
        switch self {
        case .easy: return 5...12
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
    
    /// Calculate win probability based on Focus Power difference
    /// Formula: 50% + (FP Difference / 20)%, capped between 20% and 80%
    /// - Parameters:
    ///   - userFP: User's Focus Power
    ///   - opponentFP: Opponent's Focus Power
    /// - Returns: Win probability as a Double between 0.0 and 1.0
    static func calculateWinProbability(userFP: Int, opponentFP: Int) -> Double {
        let fpDifference = userFP - opponentFP
        let probabilityAdjustment = Double(fpDifference) / 20.0
        let baseProbability = 0.5 // 50%
        let rawProbability = baseProbability + (probabilityAdjustment / 100.0)
        
        // Cap between 20% and 80%
        return max(0.2, min(0.8, rawProbability))
    }
    
    /// Determine difficulty tier based on Focus Power difference
    /// - Parameters:
    ///   - userFP: User's Focus Power
    ///   - opponentFP: Opponent's Focus Power
    /// - Returns: DifficultyTier (easy, fair, or hard)
    static func determineDifficulty(userFP: Int, opponentFP: Int) -> DifficultyTier {
        let fpDifference = userFP - opponentFP
        
        if fpDifference >= 200 {
            return .easy // User is 200+ stronger
        } else if fpDifference <= -200 {
            return .hard // Opponent is 200+ stronger
        } else {
            return .fair // Within ±200
        }
    }
    
    /// Simulate a battle and determine outcome
    /// - Parameters:
    ///   - userFP: User's Focus Power
    ///   - opponentFP: Opponent's Focus Power
    /// - Returns: Tuple with win status and difficulty tier
    static func simulateBattle(userFP: Int, opponentFP: Int) -> (didWin: Bool, difficulty: DifficultyTier) {
        let difficulty = determineDifficulty(userFP: userFP, opponentFP: opponentFP)
        let winProbability = calculateWinProbability(userFP: userFP, opponentFP: opponentFP)
        
        // Random roll between 0.0 and 1.0
        let randomRoll = Double.random(in: 0.0...1.0)
        let didWin = randomRoll < winProbability
        
        return (didWin: didWin, difficulty: difficulty)
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
    
    /// Calculate rewards based on battle outcome
    /// - Parameters:
    ///   - didWin: Whether the user won the battle
    ///   - difficulty: Difficulty tier of the opponent
    ///   - exactGold: Pre-calculated exact gold amount (if nil, generates random)
    /// - Returns: Tuple with XP and Gold earned
    static func calculateRewards(didWin: Bool, difficulty: DifficultyTier, exactGold: Int? = nil) -> (xp: Int, gold: Int) {
        let xp: Int
        let gold: Int
        
        if didWin {
            xp = 50
            // Use exact gold if provided, otherwise generate random
            gold = exactGold ?? Int.random(in: difficulty.goldRange)
        } else {
            xp = 10
            gold = 0 // No gold for losses
        }
        
        return (xp: xp, gold: gold)
    }
    
    /// Execute a complete battle simulation
    /// - Parameters:
    ///   - userFP: User's Focus Power
    ///   - opponentFP: Opponent's Focus Power
    ///   - opponentName: Name of the opponent
    ///   - opponentId: Unique identifier for the opponent (for deterministic gold)
    ///   - exactGold: Pre-calculated exact gold amount (optional, will be calculated if nil)
    /// - Returns: BattleResult with all battle information
    static func executeBattle(userFP: Int, opponentFP: Int, opponentName: String, opponentId: String? = nil, exactGold: Int? = nil) -> BattleResult {
        let (didWin, difficulty) = simulateBattle(userFP: userFP, opponentFP: opponentFP)
        
        // Calculate exact gold if not provided
        let goldAmount: Int
        if let exact = exactGold {
            goldAmount = exact
        } else if let id = opponentId {
            goldAmount = calculateExactGold(opponentId: id, difficulty: difficulty)
        } else {
            goldAmount = Int.random(in: difficulty.goldRange)
        }
        
        let (xp, gold) = calculateRewards(didWin: didWin, difficulty: difficulty, exactGold: didWin ? goldAmount : nil)
        
        return BattleResult(
            didWin: didWin,
            xpEarned: xp,
            goldEarned: gold,
            opponentName: opponentName,
            difficultyTier: difficulty
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

