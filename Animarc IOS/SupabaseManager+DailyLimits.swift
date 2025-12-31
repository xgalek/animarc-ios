//
//  SupabaseManager+DailyLimits.swift
//  Animarc IOS
//
//  Daily limits tracking for freemium features
//

import Foundation
import Supabase

// MARK: - Daily Limits Model

struct UserDailyLimits: Codable {
    let id: UUID
    let userId: UUID
    var date: Date
    var bossAttemptsUsed: Int
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case bossAttemptsUsed = "boss_attempts_used"
        case updatedAt = "updated_at"
    }
    
    /// Custom decoder to handle date-only strings (e.g., "2025-12-30")
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        bossAttemptsUsed = try container.decode(Int.self, forKey: .bossAttemptsUsed)
        
        // Handle date field - can be date-only string or full ISO8601
        if let dateString = try? container.decode(String.self, forKey: .date) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            // Try date-only format first (YYYY-MM-DD)
            formatter.dateFormat = "yyyy-MM-dd"
            if let parsedDate = formatter.date(from: dateString) {
                date = parsedDate
            } else {
                // Try ISO8601 format
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
                if let parsedDate = formatter.date(from: dateString) {
                    date = parsedDate
                } else {
                    // Fallback to current date
                    date = Date()
                }
            }
        } else if let dateValue = try? container.decode(Date.self, forKey: .date) {
            date = dateValue
        } else {
            date = Date()
        }
        
        // Handle updatedAt - decode as optional first, then provide default
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    /// Memberwise initializer (required when custom decoder is present)
    init(
        id: UUID,
        userId: UUID,
        date: Date,
        bossAttemptsUsed: Int,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.bossAttemptsUsed = bossAttemptsUsed
        self.updatedAt = updatedAt
    }
}

// MARK: - Daily Limits Extension

extension SupabaseManager {
    
    /// Fetch or create daily limits record for today
    /// - Parameter userId: The user's UUID
    /// - Returns: UserDailyLimits for today
    func fetchOrCreateDailyLimits(userId: UUID) async throws -> UserDailyLimits {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Try to fetch today's record
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let todayString = formatter.string(from: today)
        
        let response: [UserDailyLimits] = try await client
            .from("user_daily_limits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: todayString)
            .limit(1)
            .execute()
            .value
        
        if let existing = response.first {
            return existing
        }
        
        // Create new record for today
        struct NewDailyLimits: Codable {
            let user_id: String
            let date: Date
            let boss_attempts_used: Int
        }
        
        let newLimits = NewDailyLimits(
            user_id: userId.uuidString,
            date: today,
            boss_attempts_used: 0
        )
        
        let created: [UserDailyLimits] = try await client
            .from("user_daily_limits")
            .insert(newLimits)
            .select()
            .execute()
            .value
        
        guard let result = created.first else {
            throw GamificationError.userProgressNotFound
        }
        
        return result
    }
    
    /// Get remaining boss attempts for today
    /// - Parameter userId: The user's UUID
    /// - Parameter isPro: Whether user has Pro subscription
    /// - Returns: Remaining attempts (Free: 1/day, Pro: 3/day)
    func getRemainingBossAttempts(userId: UUID, isPro: Bool) async throws -> Int {
        let limits = try await fetchOrCreateDailyLimits(userId: userId)
        let maxAttempts = isPro ? 3 : 1
        return max(0, maxAttempts - limits.bossAttemptsUsed)
    }
    
    /// Check if user can attempt a boss battle
    /// - Parameter userId: The user's UUID
    /// - Parameter isPro: Whether user has Pro subscription
    /// - Returns: True if user has attempts remaining
    func canAttemptBoss(userId: UUID, isPro: Bool) async throws -> Bool {
        let remaining = try await getRemainingBossAttempts(userId: userId, isPro: isPro)
        return remaining > 0
    }
    
    /// Increment boss attempts used for today
    /// - Parameter userId: The user's UUID
    /// - Returns: Updated UserDailyLimits
    func incrementBossAttempts(userId: UUID) async throws -> UserDailyLimits {
        let limits = try await fetchOrCreateDailyLimits(userId: userId)
        
        struct AttemptUpdate: Codable {
            let boss_attempts_used: Int
            let updated_at: Date
        }
        
        let update = AttemptUpdate(
            boss_attempts_used: limits.bossAttemptsUsed + 1,
            updated_at: Date()
        )
        
        let response: [UserDailyLimits] = try await client
            .from("user_daily_limits")
            .update(update)
            .eq("id", value: limits.id.uuidString)
            .select()
            .execute()
            .value
        
        guard let updated = response.first else {
            throw GamificationError.userProgressNotFound
        }
        
        return updated
    }
}

