//
//  GamificationSetting.swift
//  Animarc IOS
//
//  XP rates and configuration (read-only reference data)
//

import Foundation

/// Maps to Supabase table: gamification_settings
struct GamificationSetting: Codable, Identifiable {
    let id: UUID
    let settingKey: String
    let settingValue: SettingValue  // Can be string or number
    let settingDescription: String
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case settingKey = "setting_key"
        case settingValue = "setting_value"
        case settingDescription = "setting_description"
        case updatedAt = "updated_at"
    }
    
    /// Get value as string
    var stringValue: String {
        switch settingValue {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        }
    }
    
    /// Get value as integer (if possible)
    var intValue: Int? {
        switch settingValue {
        case .string(let s): return Int(s)
        case .int(let i): return i
        case .double(let d): return Int(d)
        }
    }
}

/// Wrapper to handle setting_value which can be String, Int, or Double in the database
enum SettingValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try decoding as Int first
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }
        
        // Try decoding as Double
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }
        
        // Fall back to String
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        
        throw DecodingError.typeMismatch(
            SettingValue.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String, Int, or Double")
        )
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        }
    }
}
