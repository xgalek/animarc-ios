//
//  LevelService.swift
//  Animarc IOS
//
//  Level calculation from XP, progress percentage
//

import Foundation

/// Types of XP progression curves
enum XPCurveType {
    /// XP = 100 * (level ^ 1.5) - Default progressive curve
    case progressive
    /// XP = 100 * level - Linear progression
    case linear
}

/// Result of level progress calculation
struct LevelProgress {
    let currentLevel: Int
    let nextLevel: Int
    let xpInCurrentLevel: Int
    let xpNeededForNext: Int
    let progressPercent: Double
    
    /// Formatted progress string (e.g., "76 / 282 XP")
    var progressText: String {
        let xpForNext = LevelService.getXPForLevel(nextLevel)
        return "\(xpInCurrentLevel) / \(xpNeededForNext) XP"
    }
}

/// Service for level calculations based on XP
final class LevelService {
    
    // MARK: - Configuration
    
    /// Maximum achievable level
    static let maxLevel: Int = 150
    
    /// XP curve type used for calculations
    static let curveType: XPCurveType = .progressive
    
    // MARK: - XP Thresholds
    
    /// Get total XP required to reach a specific level
    /// Level 1 starts at 0 XP
    /// Level 2 starts at 100 XP
    /// Level N starts at 100 * ((N-1) ^ 1.5) XP
    /// - Parameter level: Target level (1-150)
    /// - Returns: Total XP required to reach that level
    static func getXPForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }  // Level 1 starts at 0 XP
        
        switch curveType {
        case .progressive:
            // Level 2 = 100, Level 3 = 282, Level 4 = 519, etc.
            return Int(100.0 * pow(Double(level - 1), 1.5))
        case .linear:
            return 100 * (level - 1)
        }
    }
    
    /// Get the XP required to go from level N to level N+1
    /// - Parameter level: Current level
    /// - Returns: XP needed to advance to next level
    static func getXPBetweenLevels(_ level: Int) -> Int {
        return getXPForLevel(level + 1) - getXPForLevel(level)
    }
    
    // MARK: - Level Calculation
    
    /// Calculate current level from total XP
    /// - Parameter xp: Total XP earned
    /// - Returns: Current level (1 to maxLevel)
    static func getLevelFromXP(_ xp: Int) -> Int {
        guard xp >= 0 else { return 1 }
        
        var level = 1
        let maxLvl = maxLevel > 0 ? maxLevel : 9999
        
        // Level up while XP >= threshold for next level
        while level < maxLvl && xp >= getXPForLevel(level + 1) {
            level += 1
        }
        
        return min(level, maxLvl)
    }
    
    /// Get detailed progress information for a given total XP
    /// - Parameter totalXP: Total XP earned
    /// - Returns: LevelProgress with all progress details
    static func getLevelProgress(totalXP: Int) -> LevelProgress {
        let currentLevel = getLevelFromXP(totalXP)
        
        // Handle max level case
        if currentLevel >= maxLevel {
            return LevelProgress(
                currentLevel: currentLevel,
                nextLevel: currentLevel,
                xpInCurrentLevel: 0,
                xpNeededForNext: 0,
                progressPercent: 100.0
            )
        }
        
        let xpForCurrent = getXPForLevel(currentLevel)
        let xpForNext = getXPForLevel(currentLevel + 1)
        let xpInCurrentLevel = max(0, totalXP - xpForCurrent)
        let xpNeeded = xpForNext - xpForCurrent
        
        let progress: Double
        if xpNeeded > 0 {
            progress = min(100.0, max(0.0, Double(xpInCurrentLevel) / Double(xpNeeded) * 100.0))
        } else {
            progress = 100.0
        }
        
        return LevelProgress(
            currentLevel: currentLevel,
            nextLevel: currentLevel + 1,
            xpInCurrentLevel: xpInCurrentLevel,
            xpNeededForNext: xpNeeded,
            progressPercent: progress
        )
    }
    
    /// Check if gaining XP resulted in a level up
    /// - Parameters:
    ///   - oldXP: XP before gain
    ///   - newXP: XP after gain
    /// - Returns: Tuple of (didLevelUp, oldLevel, newLevel) or nil if no level up
    static func checkLevelUp(oldXP: Int, newXP: Int) -> (oldLevel: Int, newLevel: Int)? {
        let oldLevel = getLevelFromXP(oldXP)
        let newLevel = getLevelFromXP(newXP)
        
        if newLevel > oldLevel {
            return (oldLevel, newLevel)
        }
        return nil
    }
}
