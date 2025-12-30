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
