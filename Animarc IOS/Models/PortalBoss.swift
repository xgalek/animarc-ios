//
//  PortalBoss.swift
//  Animarc IOS
//
//  Portal boss configuration model
//

import Foundation
import SwiftUI

/// Maps to Supabase table: portal_bosses
struct PortalBoss: Codable, Identifiable {
    let id: UUID
    let name: String
    let rank: String
    let imageName: String
    let specialization: String
    let statHealth: Int
    let statAttack: Int
    let statDefense: Int
    let statSpeed: Int
    let maxHp: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rank
        case imageName = "image_name"
        case specialization
        case statHealth = "stat_health"
        case statAttack = "stat_attack"
        case statDefense = "stat_defense"
        case statSpeed = "stat_speed"
        case maxHp = "max_hp"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var rankColor: Color {
        RankService.getRankByCode(rank)?.swiftUIColor ?? Color.gray
    }
    
    var specializationColor: Color {
        switch specialization {
        case "Tank": return Color(hex: "#3B82F6")
        case "Glass Cannon": return Color(hex: "#EF4444")
        case "Speedster": return Color(hex: "#F59E0B")
        case "Balanced": return Color(hex: "#10B981")
        default: return Color.gray
        }
    }
    
    /// Convert to BattlerStats for battle calculations
    var battlerStats: BattlerStats {
        BattlerStats(
            health: statHealth,
            attack: statAttack,
            defense: statDefense,
            speed: statSpeed,
            level: RankService.getRankForLevel(statHealth / 10).minLevel,
            focusPower: 0 // Not used for bosses
        )
    }
}

