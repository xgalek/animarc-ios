//
//  RankService.swift
//  Animarc IOS
//
//  Rank thresholds and colors
//

import Foundation
import SwiftUI

/// Rank information with code, level threshold, and color
struct RankInfo {
    let code: String
    let title: String
    let minLevel: Int
    let color: String
    
    /// SwiftUI Color from hex string
    var swiftUIColor: Color {
        Color(hex: color)
    }
    
    /// Asset catalog image name for the rank badge, nil if no badge exists
    var badgeImageName: String? {
        switch code {
        case "E", "D", "C", "B", "A", "S":
            return "\(code)_rank"
        default:
            return nil
        }
    }
}

/// Service for rank determination based on level
final class RankService {
    
    // MARK: - Default Rank Thresholds
    
    /// All ranks in ascending order
    static let allRanks: [RankInfo] = [
        RankInfo(code: "E", title: "Beginner Scholar", minLevel: 1, color: "#4A90A4"),
        RankInfo(code: "D", title: "Rising Student", minLevel: 10, color: "#CD7F32"),
        RankInfo(code: "C", title: "Focused Apprentice", minLevel: 25, color: "#4CAF50"),
        RankInfo(code: "B", title: "Dedicated Learner", minLevel: 45, color: "#2196F3"),
        RankInfo(code: "A", title: "Elite Scholar", minLevel: 70, color: "#9C27B0"),
        RankInfo(code: "S", title: "Master of Focus", minLevel: 100, color: "#FFD700"),
        RankInfo(code: "SS", title: "Legendary Hunter", minLevel: 130, color: "#E6A8D7"),
        RankInfo(code: "SSS", title: "Transcendent Being", minLevel: 150, color: "#FFFFFF"),
    ]
    
    // MARK: - Rank Determination
    
    /// Get rank info for a given level
    /// - Parameter level: Current level
    /// - Returns: RankInfo for the appropriate rank
    static func getRankForLevel(_ level: Int) -> RankInfo {
        // Find highest rank where level >= minLevel
        let rank = allRanks.reversed().first { level >= $0.minLevel }
        return rank ?? allRanks[0]
    }
    
    /// Get rank info by rank code
    /// - Parameter code: Rank code (E, D, C, B, A, S, SS, SSS)
    /// - Returns: RankInfo if found, nil otherwise
    static func getRankByCode(_ code: String) -> RankInfo? {
        return allRanks.first { $0.code == code }
    }
    
    /// Check if user ranked up between two levels
    /// - Parameters:
    ///   - oldLevel: Previous level
    ///   - newLevel: New level
    /// - Returns: Tuple of (oldRank, newRank) if ranked up, nil otherwise
    static func checkForRankUp(oldLevel: Int, newLevel: Int) -> (oldRank: RankInfo, newRank: RankInfo)? {
        let oldRank = getRankForLevel(oldLevel)
        let newRank = getRankForLevel(newLevel)
        
        if oldRank.code != newRank.code {
            return (oldRank, newRank)
        }
        return nil
    }
    
    /// Get progress to next rank
    /// - Parameter level: Current level
    /// - Returns: Tuple of (currentRank, nextRank, levelsToNextRank) or nil if at max rank
    static func getProgressToNextRank(_ level: Int) -> (current: RankInfo, next: RankInfo, levelsRemaining: Int)? {
        let currentRank = getRankForLevel(level)
        
        // Find next rank
        guard let currentIndex = allRanks.firstIndex(where: { $0.code == currentRank.code }),
              currentIndex < allRanks.count - 1 else {
            return nil // Already at max rank
        }
        
        let nextRank = allRanks[currentIndex + 1]
        let levelsRemaining = nextRank.minLevel - level
        
        return (currentRank, nextRank, levelsRemaining)
    }
    
    /// Update ranks from database (if loaded from Supabase ranks table)
    /// - Parameter ranks: Array of Rank from database
    static func updateRanks(from ranks: [Rank]) {
        // For now, we use hardcoded ranks
        // This could be extended to use database-loaded ranks
        print("Loaded \(ranks.count) ranks from database")
    }
    
    /// Get a deterministic boss level within a rank's range based on a seed value
    /// - Parameters:
    ///   - rankCode: The rank code (E, D, C, etc.)
    ///   - seed: A seed value (e.g., boss ID hash) to make it deterministic
    /// - Returns: A level within the rank's range
    static func getBossLevelForRank(rankCode: String, seed: Int) -> Int {
        guard let rankInfo = getRankByCode(rankCode) else {
            return 1
        }
        
        // Find the next rank to determine the upper bound
        guard let currentIndex = allRanks.firstIndex(where: { $0.code == rankCode }),
              currentIndex < allRanks.count - 1 else {
            // Highest rank (SSS), use a reasonable max (e.g., 200)
            let minLevel = rankInfo.minLevel
            let maxLevel = 200
            let range = maxLevel - minLevel + 1
            return minLevel + (abs(seed) % range)
        }
        
        let nextRank = allRanks[currentIndex + 1]
        let minLevel = rankInfo.minLevel
        let maxLevel = nextRank.minLevel - 1 // One less than next rank's minLevel
        let range = maxLevel - minLevel + 1
        
        // Use seed to deterministically pick a level within the range
        return minLevel + (abs(seed) % range)
    }
}

