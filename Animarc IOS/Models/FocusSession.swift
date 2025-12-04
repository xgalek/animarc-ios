//
//  FocusSession.swift
//  Animarc IOS
//
//  Individual focus session records
//

import Foundation

/// Maps to Supabase table: focus_sessions
struct FocusSession: Codable, Identifiable {
    let id: UUID
    var userId: UUID?
    var durationMinutes: Int
    var xpEarned: Int
    let completedAt: Date
    var bonusXpEarned: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case durationMinutes = "duration_minutes"
        case xpEarned = "xp_earned"
        case completedAt = "completed_at"
        case bonusXpEarned = "bonus_xp_earned"
        case createdAt = "created_at"
    }
}

// MARK: - Insert Model

/// Model for inserting a new focus session (without id, createdAt auto-generated)
struct NewFocusSession: Codable {
    let userId: String
    let durationMinutes: Int
    let xpEarned: Int
    let completedAt: Date
    let bonusXpEarned: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case durationMinutes = "duration_minutes"
        case xpEarned = "xp_earned"
        case completedAt = "completed_at"
        case bonusXpEarned = "bonus_xp_earned"
    }
}

