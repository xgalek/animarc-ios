//
//  UserProgress.swift
//  Animarc IOS
//
//  Core user stats: level, XP, rank, focus time, sessions
//

import Foundation

/// Maps to Supabase table: user_progress
struct UserProgress: Codable, Identifiable, Equatable {
    let id: UUID
    var userId: UUID?
    var currentLevel: Int
    var currentXP: Int
    var totalXPEarned: Int64
    var currentRank: String
    var totalFocusMinutes: Int
    var totalSessionsCompleted: Int
    var displayName: String?
    let createdAt: Date
    var updatedAt: Date
    
    // Stat system fields
    var availableStatPoints: Int
    var statSTR: Int
    var statAGI: Int
    var statINT: Int
    var statVIT: Int
    
    // Currency
    var gold: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentLevel = "current_level"
        case currentXP = "current_xp"
        case totalXPEarned = "total_xp_earned"
        case currentRank = "current_rank"
        case totalFocusMinutes = "total_focus_minutes"
        case totalSessionsCompleted = "total_sessions_completed"
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case availableStatPoints = "available_stat_points"
        case statSTR = "stat_str"
        case statAGI = "stat_agi"
        case statINT = "stat_int"
        case statVIT = "stat_vit"
        case gold
    }
}

// MARK: - Default Values

extension UserProgress {
    /// Create a default user progress for display while loading
    static var placeholder: UserProgress {
        UserProgress(
            id: UUID(),
            userId: nil,
            currentLevel: 1,
            currentXP: 0,
            totalXPEarned: 0,
            currentRank: "E",
            totalFocusMinutes: 0,
            totalSessionsCompleted: 0,
            displayName: nil,
            createdAt: Date(),
            updatedAt: Date(),
            availableStatPoints: 0,
            statSTR: 10,
            statAGI: 10,
            statINT: 10,
            statVIT: 10,
            gold: 0
        )
    }
    
    /// Calculate HP based on STR: HP = 150 + (STR * 5)
    var calculatedHP: Int {
        return 150 + (statSTR * 5)
    }
    
    /// Calculate total base stats for Focus Power formula
    var totalBaseStats: Int {
        return statSTR + statAGI + statINT + statVIT
    }
    
    /// Calculate total Focus Power
    /// - Parameters:
    ///   - progress: User's progress data (stats + focus minutes)
    ///   - equippedItems: Array of currently equipped PortalItems
    /// - Returns: Total Focus Power value
    static func calculateFocusPower(progress: UserProgress, equippedItems: [PortalItem]) -> Int {
        let basePower = 1000
        let totalStats = progress.totalBaseStats
        let focusMinutes = progress.totalFocusMinutes
        let equipmentBonus = equippedItems.reduce(0) { $0 + $1.statValue }
        
        return basePower + totalStats + focusMinutes + equipmentBonus
    }
}

