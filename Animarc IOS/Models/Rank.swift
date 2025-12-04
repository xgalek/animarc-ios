//
//  Rank.swift
//  Animarc IOS
//
//  Rank definitions (read-only reference data)
//

import Foundation

/// Maps to Supabase table: ranks
struct Rank: Codable, Identifiable {
    let id: UUID
    let rankCode: String
    let rankTitle: String
    let minLevel: Int
    let maxLevel: Int
    let xpThresholdMin: Int
    let xpThresholdMax: Int
    let badgeIconUrl: String?
    let badgeColor: String
    let displayOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case rankCode = "rank_code"
        case rankTitle = "rank_title"
        case minLevel = "min_level"
        case maxLevel = "max_level"
        case xpThresholdMin = "xp_threshold_min"
        case xpThresholdMax = "xp_threshold_max"
        case badgeIconUrl = "badge_icon_url"
        case badgeColor = "badge_color"
        case displayOrder = "display_order"
    }
}

