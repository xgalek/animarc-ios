//
//  PortalRaidProgress.swift
//  Animarc IOS
//
//  User portal raid progress tracking model
//

import Foundation

/// Maps to Supabase table: portal_progress
struct PortalRaidProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let portalBossId: UUID
    var currentDamage: Int
    let maxHp: Int
    var progressPercent: Double
    var completed: Bool
    var completedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case portalBossId = "portal_boss_id"
        case currentDamage = "current_damage"
        case maxHp = "max_hp"
        case progressPercent = "progress_percent"
        case completed
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Custom decoder to handle date parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        portalBossId = try container.decode(UUID.self, forKey: .portalBossId)
        currentDamage = try container.decode(Int.self, forKey: .currentDamage)
        maxHp = try container.decode(Int.self, forKey: .maxHp)
        progressPercent = try container.decode(Double.self, forKey: .progressPercent)
        completed = try container.decode(Bool.self, forKey: .completed)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        
        // Handle dates - decode as optional first, then provide default
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    /// Memberwise initializer (required when custom decoder is present)
    init(
        id: UUID,
        userId: UUID,
        portalBossId: UUID,
        currentDamage: Int,
        maxHp: Int,
        progressPercent: Double,
        completed: Bool,
        completedAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.portalBossId = portalBossId
        self.currentDamage = currentDamage
        self.maxHp = maxHp
        self.progressPercent = progressPercent
        self.completed = completed
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var remainingHp: Int {
        max(0, maxHp - currentDamage)
    }
    
    var isNearCompletion: Bool {
        progressPercent >= 70.0
    }
    
    /// Update progress with new damage
    mutating func applyDamage(_ damage: Int) {
        currentDamage = min(maxHp, currentDamage + damage)
        progressPercent = min(100.0, (Double(currentDamage) / Double(maxHp)) * 100)
        
        if currentDamage >= maxHp && !completed {
            completed = true
            completedAt = Date()
        }
        
        updatedAt = Date()
    }
}

/// Result of a single raid attempt
struct RaidAttemptResult {
    let damageDealt: Int
    let newTotalDamage: Int
    let newProgressPercent: Double
    let bossDefeated: Bool
    let userSurvived: Bool
}




