//
//  SupabaseManager+PortalRaids.swift
//  Animarc IOS
//
//  Database methods for portal raid system
//

import Foundation
import Supabase

// MARK: - Portal Bosses

extension SupabaseManager {
    
    /// Fetch all portal bosses from database
    /// - Returns: Array of PortalBoss
    func fetchAllPortalBosses() async throws -> [PortalBoss] {
        return try await withRetry {
            try await self.client
                .from("portal_bosses")
                .select()
                .execute()
                .value
        }
    }
    
    /// Fetch available portal bosses for user's rank range
    /// - Parameter userRank: User's current rank code
    /// - Returns: Array of PortalBoss filtered by rank
    func fetchAvailablePortalBosses(userRank: String) async throws -> [PortalBoss] {
        return try await withRetry {
            // Get current rank and next rank
            let ranks = ["E", "D", "C", "B", "A", "S", "SS", "SSS"]
            guard let currentIndex = ranks.firstIndex(of: userRank) else {
                return try await self.fetchAllPortalBosses()
            }
            
            let nextRank = currentIndex < ranks.count - 1 ? ranks[currentIndex + 1] : nil
            
            var query = self.client
                .from("portal_bosses")
                .select()
                .in("rank", value: [userRank])
            
            if let nextRank = nextRank {
                // Fetch current rank and next rank bosses
                let bosses: [PortalBoss] = try await self.client
                    .from("portal_bosses")
                    .select()
                    .in("rank", value: [userRank, nextRank])
                    .execute()
                    .value
                return bosses
            } else {
                // At max rank, only fetch current rank
                return try await query.execute().value
            }
        }
    }
}

// MARK: - Portal Progress

extension SupabaseManager {
    
    /// Fetch user's progress on all portal bosses
    /// - Parameter userId: The user's UUID
    /// - Returns: Array of PortalRaidProgress
    func fetchPortalProgress(userId: UUID) async throws -> [PortalRaidProgress] {
        return try await withRetry {
            try await self.client
                .from("portal_progress")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
        }
    }
    
    /// Fetch user's progress for a specific boss
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - bossId: The boss's UUID
    /// - Returns: PortalRaidProgress if found, nil otherwise
    func fetchPortalProgress(userId: UUID, bossId: UUID) async throws -> PortalRaidProgress? {
        return try await withRetry {
            let response: [PortalRaidProgress] = try await self.client
                .from("portal_progress")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("portal_boss_id", value: bossId.uuidString)
                .limit(1)
                .execute()
                .value
            
            return response.first
        }
    }
    
    /// Create progress entry for a new boss
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - bossId: The boss's UUID
    ///   - maxHp: Boss's max HP
    /// - Returns: Newly created PortalRaidProgress
    func createPortalProgress(userId: UUID, bossId: UUID, maxHp: Int) async throws -> PortalRaidProgress {
        return try await withRetry {
            struct NewProgress: Codable {
                let user_id: String
                let portal_boss_id: String
                let current_damage: Int
                let max_hp: Int
                let progress_percent: Double
                let completed: Bool
            }
            
            let newProgress = NewProgress(
                user_id: userId.uuidString,
                portal_boss_id: bossId.uuidString,
                current_damage: 0,
                max_hp: maxHp,
                progress_percent: 0.0,
                completed: false
            )
            
            let response: [PortalRaidProgress] = try await self.client
                .from("portal_progress")
                .insert(newProgress)
                .select()
                .execute()
                .value
            
            guard let created = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return created
        }
    }
    
    /// Update progress after raid attempt
    /// - Parameters:
    ///   - progressId: Progress record UUID
    ///   - newDamage: New total damage value
    ///   - newPercent: New progress percentage
    /// - Returns: Updated PortalRaidProgress
    func updatePortalProgress(progressId: UUID, newDamage: Int, newPercent: Double) async throws -> PortalRaidProgress {
        return try await withRetry {
            struct ProgressUpdate: Codable {
                let current_damage: Int
                let progress_percent: Double
                let updated_at: Date
            }
            
            let update = ProgressUpdate(
                current_damage: newDamage,
                progress_percent: newPercent,
                updated_at: Date()
            )
            
            let response: [PortalRaidProgress] = try await self.client
                .from("portal_progress")
                .update(update)
                .eq("id", value: progressId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated
        }
    }
    
    /// Mark boss as defeated (complete portal)
    /// - Parameter progressId: Progress record UUID
    /// - Returns: Updated PortalRaidProgress
    func completePortalBoss(progressId: UUID) async throws -> PortalRaidProgress {
        return try await withRetry {
            struct CompletionUpdate: Codable {
                let completed: Bool
                let completed_at: Date
                let updated_at: Date
            }
            
            let update = CompletionUpdate(
                completed: true,
                completed_at: Date(),
                updated_at: Date()
            )
            
            let response: [PortalRaidProgress] = try await self.client
                .from("portal_progress")
                .update(update)
                .eq("id", value: progressId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated
        }
    }
    
    /// Fetch or create progress entry for a boss
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - bossId: The boss's UUID
    ///   - maxHp: Boss's max HP (used if creating new)
    /// - Returns: Existing or new PortalRaidProgress
    func fetchOrCreatePortalProgress(userId: UUID, bossId: UUID, maxHp: Int) async throws -> PortalRaidProgress {
        if let existing = try await fetchPortalProgress(userId: userId, bossId: bossId) {
            return existing
        }
        return try await createPortalProgress(userId: userId, bossId: bossId, maxHp: maxHp)
    }
}

// MARK: - Portal Attempts

extension SupabaseManager {
    
    /// Consume one portal attempt
    /// - Parameter userId: The user's UUID
    /// - Returns: Remaining attempts after consumption
    func consumePortalAttempt(userId: UUID) async throws -> Int {
        return try await withRetry {
            // Check and reset daily attempts if needed
            let remaining = try await self.checkAndResetDailyAttempts(userId: userId)
            
            guard remaining > 0 else {
                throw GamificationError.userProgressNotFound // TODO: Create proper error
            }
            
            // Fetch current progress
            guard let progress = try await self.fetchUserProgress(userId: userId) else {
                throw GamificationError.userProgressNotFound
            }
            
            // Decrement attempts
            struct AttemptUpdate: Codable {
                let portal_attempts: Int
            }
            
            let newAttempts = max(0, (progress.portalAttempts ?? 50) - 1)
            let update = AttemptUpdate(portal_attempts: newAttempts)
            
            let response: [UserProgress] = try await self.client
                .from("user_progress")
                .update(update)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated.portalAttempts ?? 0
        }
    }
    
    /// Check and reset daily attempts if needed
    /// - Parameter userId: The user's UUID
    /// - Returns: Current remaining attempts
    func checkAndResetDailyAttempts(userId: UUID) async throws -> Int {
        return try await withRetry {
            guard let progress = try await self.fetchUserProgress(userId: userId) else {
                throw GamificationError.userProgressNotFound
            }
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            // Check if last reset was today
            if let lastReset = progress.lastAttemptReset {
                let lastResetDay = calendar.startOfDay(for: lastReset)
                if lastResetDay == today {
                    // Already reset today, return current attempts
                    return progress.portalAttempts ?? 50
                }
            }
            
            // Need to reset - set attempts to 50 and update reset date
            struct ResetUpdate: Codable {
                let portal_attempts: Int
                let last_attempt_reset: Date
            }
            
            let update = ResetUpdate(
                portal_attempts: 50,
                last_attempt_reset: today
            )
            
            let response: [UserProgress] = try await self.client
                .from("user_progress")
                .update(update)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated.portalAttempts ?? 50
        }
    }
    
    /// Get current portal attempts without consuming
    /// - Parameter userId: The user's UUID
    /// - Returns: Current remaining attempts
    func getPortalAttempts(userId: UUID) async throws -> Int {
        let remaining = try await checkAndResetDailyAttempts(userId: userId)
        return remaining
    }
}

