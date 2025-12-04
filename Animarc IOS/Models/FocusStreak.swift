//
//  FocusStreak.swift
//  Animarc IOS
//
//  Daily streak tracking
//

import Foundation

/// Maps to Supabase table: focus_streaks
struct FocusStreak: Codable, Identifiable {
    let id: UUID
    var sessionId: String?      // For web guests (nil on iOS)
    var userId: UUID?           // For authenticated users
    var currentStreak: Int
    var longestStreak: Int
    var lastVisitDate: Date?    // DATE type from Postgres (YYYY-MM-DD)
    var totalVisits: Int
    var streakMilestones: [String]?  // JSONB array
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastVisitDate = "last_visit_date"
        case totalVisits = "total_visits"
        case streakMilestones = "streak_milestones"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder to handle DATE format (YYYY-MM-DD) from Postgres
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        totalVisits = try container.decode(Int.self, forKey: .totalVisits)
        streakMilestones = try container.decodeIfPresent([String].self, forKey: .streakMilestones)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Handle lastVisitDate which can be a DATE (YYYY-MM-DD) or null
        if let dateString = try? container.decodeIfPresent(String.self, forKey: .lastVisitDate) {
            // Try parsing as DATE format (YYYY-MM-DD)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            lastVisitDate = dateFormatter.date(from: dateString)
        } else {
            // Try decoding as Date directly (for full timestamp)
            lastVisitDate = try? container.decodeIfPresent(Date.self, forKey: .lastVisitDate)
        }
    }
}

// MARK: - Insert Model

/// Model for inserting a new streak record (iOS uses user_id)
struct NewFocusStreak: Codable {
    let userId: String
    let currentStreak: Int
    let longestStreak: Int
    let lastVisitDate: Date
    let totalVisits: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastVisitDate = "last_visit_date"
        case totalVisits = "total_visits"
    }
}

// MARK: - Default Values

extension FocusStreak {
    /// Create a default streak for display while loading
    static var placeholder: FocusStreak {
        FocusStreak(
            id: UUID(),
            sessionId: nil,
            userId: nil,
            currentStreak: 0,
            longestStreak: 0,
            lastVisitDate: nil,
            totalVisits: 0,
            streakMilestones: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // Manual initializer for placeholder
    init(id: UUID, sessionId: String?, userId: UUID?, currentStreak: Int, longestStreak: Int, lastVisitDate: Date?, totalVisits: Int, streakMilestones: [String]?, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.sessionId = sessionId
        self.userId = userId
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastVisitDate = lastVisitDate
        self.totalVisits = totalVisits
        self.streakMilestones = streakMilestones
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
