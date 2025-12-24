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
    var statHealth: Int
    var statAttack: Int
    var statDefense: Int
    var statSpeed: Int
    
    // Currency
    var gold: Int
    
    // Portal attempts
    var portalAttempts: Int?
    var lastAttemptReset: Date?
    
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
        case statHealth = "stat_health"
        case statAttack = "stat_attack"
        case statDefense = "stat_defense"
        case statSpeed = "stat_speed"
        case gold
        case portalAttempts = "portal_attempts"
        case lastAttemptReset = "last_attempt_reset"
    }
    
    /// Custom decoder to handle backward compatibility with missing portal_attempts fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        currentLevel = try container.decode(Int.self, forKey: .currentLevel)
        currentXP = try container.decode(Int.self, forKey: .currentXP)
        totalXPEarned = try container.decode(Int64.self, forKey: .totalXPEarned)
        currentRank = try container.decode(String.self, forKey: .currentRank)
        totalFocusMinutes = try container.decode(Int.self, forKey: .totalFocusMinutes)
        totalSessionsCompleted = try container.decode(Int.self, forKey: .totalSessionsCompleted)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        availableStatPoints = try container.decode(Int.self, forKey: .availableStatPoints)
        statHealth = try container.decode(Int.self, forKey: .statHealth)
        statAttack = try container.decode(Int.self, forKey: .statAttack)
        statDefense = try container.decode(Int.self, forKey: .statDefense)
        statSpeed = try container.decode(Int.self, forKey: .statSpeed)
        gold = try container.decode(Int.self, forKey: .gold)
        // Portal attempts fields - default to 50 if missing or null (backward compatibility)
        portalAttempts = try container.decodeIfPresent(Int.self, forKey: .portalAttempts) ?? 50
        lastAttemptReset = try container.decodeIfPresent(Date.self, forKey: .lastAttemptReset)
    }
    
    /// Memberwise initializer (required when custom decoder is present)
    init(
        id: UUID,
        userId: UUID?,
        currentLevel: Int,
        currentXP: Int,
        totalXPEarned: Int64,
        currentRank: String,
        totalFocusMinutes: Int,
        totalSessionsCompleted: Int,
        displayName: String?,
        createdAt: Date,
        updatedAt: Date,
        availableStatPoints: Int,
        statHealth: Int,
        statAttack: Int,
        statDefense: Int,
        statSpeed: Int,
        gold: Int,
        portalAttempts: Int?,
        lastAttemptReset: Date?
    ) {
        self.id = id
        self.userId = userId
        self.currentLevel = currentLevel
        self.currentXP = currentXP
        self.totalXPEarned = totalXPEarned
        self.currentRank = currentRank
        self.totalFocusMinutes = totalFocusMinutes
        self.totalSessionsCompleted = totalSessionsCompleted
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.availableStatPoints = availableStatPoints
        self.statHealth = statHealth
        self.statAttack = statAttack
        self.statDefense = statDefense
        self.statSpeed = statSpeed
        self.gold = gold
        self.portalAttempts = portalAttempts
        self.lastAttemptReset = lastAttemptReset
    }
    
    /// Custom encoder to handle optional portal_attempts fields
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(currentXP, forKey: .currentXP)
        try container.encode(totalXPEarned, forKey: .totalXPEarned)
        try container.encode(currentRank, forKey: .currentRank)
        try container.encode(totalFocusMinutes, forKey: .totalFocusMinutes)
        try container.encode(totalSessionsCompleted, forKey: .totalSessionsCompleted)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(availableStatPoints, forKey: .availableStatPoints)
        try container.encode(statHealth, forKey: .statHealth)
        try container.encode(statAttack, forKey: .statAttack)
        try container.encode(statDefense, forKey: .statDefense)
        try container.encode(statSpeed, forKey: .statSpeed)
        try container.encode(gold, forKey: .gold)
        try container.encodeIfPresent(portalAttempts, forKey: .portalAttempts)
        try container.encodeIfPresent(lastAttemptReset, forKey: .lastAttemptReset)
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
            statHealth: 150,
            statAttack: 10,
            statDefense: 10,
            statSpeed: 10,
            gold: 0,
            portalAttempts: 50,
            lastAttemptReset: nil
        )
    }
    
    /// Calculate total base stats for Focus Power formula
    /// Health is normalized to "points allocated" scale (150 = 0 points, 155 = 1 point, etc.)
    var totalBaseStats: Int {
        let healthPoints = (statHealth - 150) / 5  // Convert Health back to points scale
        return healthPoints + statAttack + statDefense + statSpeed
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

