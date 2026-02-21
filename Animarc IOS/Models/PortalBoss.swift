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
    let mapOrder: Int
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
        case mapOrder = "map_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Custom decoder to handle date parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        rank = try container.decode(String.self, forKey: .rank)
        imageName = try container.decode(String.self, forKey: .imageName)
        specialization = try container.decode(String.self, forKey: .specialization)
        statHealth = try container.decode(Int.self, forKey: .statHealth)
        statAttack = try container.decode(Int.self, forKey: .statAttack)
        statDefense = try container.decode(Int.self, forKey: .statDefense)
        statSpeed = try container.decode(Int.self, forKey: .statSpeed)
        maxHp = try container.decode(Int.self, forKey: .maxHp)
        mapOrder = try container.decodeIfPresent(Int.self, forKey: .mapOrder) ?? 0
        
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    /// Memberwise initializer (required when custom decoder is present)
    init(
        id: UUID,
        name: String,
        rank: String,
        imageName: String,
        specialization: String,
        statHealth: Int,
        statAttack: Int,
        statDefense: Int,
        statSpeed: Int,
        maxHp: Int,
        mapOrder: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.rank = rank
        self.imageName = imageName
        self.specialization = specialization
        self.statHealth = statHealth
        self.statAttack = statAttack
        self.statDefense = statDefense
        self.statSpeed = statSpeed
        self.maxHp = maxHp
        self.mapOrder = mapOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var bossLevel: Int {
        return mapOrder
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




