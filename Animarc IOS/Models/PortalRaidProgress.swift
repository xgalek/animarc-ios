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

