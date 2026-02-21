//
//  PortalModels.swift
//  Animarc IOS
//
//  Portal Items and Inventory system models
//

import Foundation
import SwiftUI

// MARK: - PortalItem

/// Represents a single portal item instance (stored in JSONB array within portal_inventory.items)
struct PortalItem: Codable, Identifiable {
    let id: UUID
    let name: String
    let iconUrl: String
    let statType: String
    let statValue: Int
    let rolledRank: String  // Rank tier item dropped at: "E", "D", "C", "B", "A", "S"
    var equipped: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconUrl = "icon_url"
        case statType = "stat_type"
        case statValue = "stat_value"
        case rolledRank = "rolled_rank"
        case equipped
    }
    
    /// Manual initializer for creating new items
    init(id: UUID, name: String, iconUrl: String, statType: String, statValue: Int, rolledRank: String, equipped: Bool) {
        self.id = id
        self.name = name
        self.iconUrl = iconUrl
        self.statType = statType
        self.statValue = statValue
        self.rolledRank = rolledRank
        self.equipped = equipped
    }
    
    /// Custom decoder to handle backward compatibility with items missing rolled_rank
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        iconUrl = try container.decode(String.self, forKey: .iconUrl)
        statType = try container.decode(String.self, forKey: .statType)
        statValue = try container.decode(Int.self, forKey: .statValue)
        // Default to "E" if rolled_rank is missing (for backward compatibility)
        rolledRank = try container.decodeIfPresent(String.self, forKey: .rolledRank) ?? "E"
        equipped = try container.decode(Bool.self, forKey: .equipped)
    }
    
    /// Custom encoder (standard encoding)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(iconUrl, forKey: .iconUrl)
        try container.encode(statType, forKey: .statType)
        try container.encode(statValue, forKey: .statValue)
        try container.encode(rolledRank, forKey: .rolledRank)
        try container.encode(equipped, forKey: .equipped)
    }
}

// MARK: - Item Rank Colors

extension PortalItem {
    /// Get color for item's rolled rank (matches rank progression colors)
    var rankColor: Color {
        switch rolledRank {
        case "E": return Color(hex: "#4A90A4")  // Teal/Cyan
        case "D": return Color(hex: "#3B82F6")  // Blue
        case "C": return Color(hex: "#A855F7")  // Purple
        case "B": return Color(hex: "#EF4444")  // Red
        case "A": return Color(hex: "#FBBF24")  // Amber
        case "S": return Color(hex: "#FFD700")  // Gold
        default: return Color(hex: "#4A90A4")
        }
    }
    
    /// Get rank display name
    var rankDisplayName: String {
        "\(rolledRank)-Rank"
    }
    
    /// Gold earned when selling this item, based on rank
    var sellPrice: Int {
        switch rolledRank {
        case "E": return 5
        case "D": return 15
        case "C": return 40
        case "B": return 80
        case "A": return 150
        case "S": return 300
        default: return 5
        }
    }
}

// MARK: - Inventory Constants

extension PortalInventory {
    static let maxItems = 20
}

// MARK: - PortalItemConfig

/// Maps to Supabase table: portal_items_config
/// Reference data defining available portal item types and their stat ranges by rank
struct PortalItemConfig: Codable, Identifiable {
    let id: UUID
    let name: String
    let iconUrl: String
    let statType: String
    let rankEMin: Int
    let rankEMax: Int
    let rankDMin: Int
    let rankDMax: Int
    let rankCMin: Int
    let rankCMax: Int
    let rankBMin: Int
    let rankBMax: Int
    let rankAMin: Int
    let rankAMax: Int
    let rankSMin: Int
    let rankSMax: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconUrl = "icon_url"
        case statType = "stat_type"
        case rankEMin = "rank_e_min"
        case rankEMax = "rank_e_max"
        case rankDMin = "rank_d_min"
        case rankDMax = "rank_d_max"
        case rankCMin = "rank_c_min"
        case rankCMax = "rank_c_max"
        case rankBMin = "rank_b_min"
        case rankBMax = "rank_b_max"
        case rankAMin = "rank_a_min"
        case rankAMax = "rank_a_max"
        case rankSMin = "rank_s_min"
        case rankSMax = "rank_s_max"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - PortalInventory

/// Maps to Supabase table: portal_inventory
/// User's portal inventory containing an array of portal items
struct PortalInventory: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var sessionId: String?
    var items: [PortalItem]
    var lastDropDate: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sessionId = "session_id"
        case items
        case lastDropDate = "last_drop_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

