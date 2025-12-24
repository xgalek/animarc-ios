//
//  SupabaseManager+Gamification.swift
//  Animarc IOS
//
//  Database methods for gamification features
//

import Foundation
import Supabase

// MARK: - User Progress

extension SupabaseManager {
    
    /// Fetch user progress for authenticated user
    /// - Parameter userId: The user's UUID
    /// - Returns: UserProgress if found, nil otherwise
    func fetchUserProgress(userId: UUID) async throws -> UserProgress? {
        return try await withRetry {
            // Use array query instead of .single() to handle empty results gracefully
            let response: [UserProgress] = try await self.client
                .from("user_progress")
                .select()
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            
            return response.first
        }
    }
    
    /// Create initial user progress record for a new user
    /// - Parameter userId: The user's UUID
    /// - Returns: Newly created UserProgress
    func createUserProgress(userId: UUID) async throws -> UserProgress {
        struct NewUserProgress: Codable {
            let user_id: String
            let current_level: Int
            let current_xp: Int
            let total_xp_earned: Int64
            let current_rank: String
            let total_focus_minutes: Int
            let total_sessions_completed: Int
            let available_stat_points: Int
            let stat_health: Int
            let stat_attack: Int
            let stat_defense: Int
            let stat_speed: Int
            let gold: Int
            let portal_attempts: Int
            let last_attempt_reset: Date
        }
        
        let newProgress = NewUserProgress(
            user_id: userId.uuidString,
            current_level: 1,
            current_xp: 0,
            total_xp_earned: 0,
            current_rank: "E",
            total_focus_minutes: 0,
            total_sessions_completed: 0,
            available_stat_points: 5,
            stat_health: 150,
            stat_attack: 10,
            stat_defense: 10,
            stat_speed: 10,
            gold: 0,
            portal_attempts: 50,
            last_attempt_reset: Calendar.current.startOfDay(for: Date())
        )
        
        let response: [UserProgress] = try await client
            .from("user_progress")
            .insert(newProgress)
            .select()
            .execute()
            .value
        
        guard let created = response.first else {
            throw GamificationError.userProgressNotFound
        }
        
        return created
    }
    
    /// Update XP, level, and rank atomically after a focus session
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - xpToAdd: Amount of XP to add
    ///   - focusMinutesIncrement: Minutes to add to total focus time
    ///   - sessionsIncrement: Number of sessions to add (usually 1)
    /// - Returns: Updated UserProgress
    func updateXP(
        userId: UUID,
        xpToAdd: Int,
        focusMinutesIncrement: Int = 0,
        sessionsIncrement: Int = 0
    ) async throws -> UserProgress {
        return try await withRetry {
            // Fetch current progress
            guard let current = try await self.fetchUserProgress(userId: userId) else {
                throw GamificationError.userProgressNotFound
            }
            
            // Calculate new values
            let newTotalXP = Int64(current.totalXPEarned) + Int64(xpToAdd)
            let newLevel = LevelService.getLevelFromXP(Int(newTotalXP))
            let newRank = RankService.getRankForLevel(newLevel).code
            
            // Calculate XP within current level for display
            // current_xp represents progress toward next level, must be >= 0
            let levelProgress = LevelService.getLevelProgress(totalXP: Int(newTotalXP))
            let newCurrentXP = max(0, levelProgress.xpInCurrentLevel)
            
            // Calculate stat points to award based on levels gained
            let levelsGained = newLevel - current.currentLevel
            let statPointsToAdd = levelsGained * 5
            let newAvailableStatPoints = current.availableStatPoints + statPointsToAdd
            
            struct UpdateData: Codable {
                let current_xp: Int
                let total_xp_earned: Int64
                let current_level: Int
                let current_rank: String
                let total_focus_minutes: Int
                let total_sessions_completed: Int
                let available_stat_points: Int
            }
            
            let updateData = UpdateData(
                current_xp: newCurrentXP,
                total_xp_earned: newTotalXP,
                current_level: newLevel,
                current_rank: newRank,
                total_focus_minutes: current.totalFocusMinutes + focusMinutesIncrement,
                total_sessions_completed: current.totalSessionsCompleted + sessionsIncrement,
                available_stat_points: newAvailableStatPoints
            )
            
            let response: [UserProgress] = try await self.client
                .from("user_progress")
                .update(updateData)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated
        }
    }
    
    /// Update stat allocation after user allocates stat points
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - statHealth: New Health value
    ///   - statAttack: New Attack value
    ///   - statDefense: New Defense value
    ///   - statSpeed: New Speed value
    ///   - pointsSpent: Number of stat points spent (will be deducted from available)
    /// - Returns: Updated UserProgress
    func updateStatAllocation(
        userId: UUID,
        statHealth: Int,
        statAttack: Int,
        statDefense: Int,
        statSpeed: Int,
        pointsSpent: Int
    ) async throws -> UserProgress {
        // Fetch current progress
        guard let current = try await fetchUserProgress(userId: userId) else {
            throw GamificationError.userProgressNotFound
        }
        
        // Validate points spent doesn't exceed available
        guard pointsSpent <= current.availableStatPoints else {
            throw GamificationError.userProgressNotFound // TODO: Create proper error type
        }
        
        struct StatUpdateData: Codable {
            let stat_health: Int
            let stat_attack: Int
            let stat_defense: Int
            let stat_speed: Int
            let available_stat_points: Int
        }
        
        let updateData = StatUpdateData(
            stat_health: statHealth,
            stat_attack: statAttack,
            stat_defense: statDefense,
            stat_speed: statSpeed,
            available_stat_points: current.availableStatPoints - pointsSpent
        )
        
        let response: [UserProgress] = try await client
            .from("user_progress")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .select()
            .execute()
            .value
        
        guard let updated = response.first else {
            throw GamificationError.userProgressNotFound
        }
        
        return updated
    }
    
    /// Update gold and XP after a battle
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - goldToAdd: Amount of gold to add (can be 0 for losses)
    ///   - xpToAdd: Amount of XP to add (50 for win, 10 for loss)
    /// - Returns: Updated UserProgress
    func updateGoldAndXP(userId: UUID, goldToAdd: Int, xpToAdd: Int) async throws -> UserProgress {
        return try await withRetry {
            // Fetch current progress
            guard let current = try await self.fetchUserProgress(userId: userId) else {
                throw GamificationError.userProgressNotFound
            }
            
            // Calculate new values
            let newTotalXP = Int64(current.totalXPEarned) + Int64(xpToAdd)
            let newLevel = LevelService.getLevelFromXP(Int(newTotalXP))
            let newRank = RankService.getRankForLevel(newLevel).code
            
            // Calculate XP within current level for display
            let levelProgress = LevelService.getLevelProgress(totalXP: Int(newTotalXP))
            let newCurrentXP = max(0, levelProgress.xpInCurrentLevel)
            
            // Calculate stat points to award based on levels gained
            let levelsGained = newLevel - current.currentLevel
            let statPointsToAdd = levelsGained * 5
            let newAvailableStatPoints = current.availableStatPoints + statPointsToAdd
            
            // Calculate new gold balance
            let newGold = current.gold + goldToAdd
            
            struct BattleUpdateData: Codable {
                let current_xp: Int
                let total_xp_earned: Int64
                let current_level: Int
                let current_rank: String
                let available_stat_points: Int
                let gold: Int
            }
            
            let updateData = BattleUpdateData(
                current_xp: newCurrentXP,
                total_xp_earned: newTotalXP,
                current_level: newLevel,
                current_rank: newRank,
                available_stat_points: newAvailableStatPoints,
                gold: newGold
            )
            
            let response: [UserProgress] = try await self.client
                .from("user_progress")
                .update(updateData)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated
        }
    }
    
    /// Update user's display name
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - newName: The new display name to set
    /// - Returns: Updated UserProgress
    func updateDisplayName(userId: UUID, newName: String) async throws -> UserProgress {
        return try await withRetry {
            struct DisplayNameUpdate: Codable {
                let display_name: String
            }
            
            let updateData = DisplayNameUpdate(display_name: newName)
            
            let response: [UserProgress] = try await self.client
                .from("user_progress")
                .update(updateData)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            
            guard let updated = response.first else {
                throw GamificationError.userProgressNotFound
            }
            
            return updated
        }
    }
}

// MARK: - Focus Sessions

extension SupabaseManager {
    
    /// Save a completed focus session to the database
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - durationMinutes: Duration of the session in minutes
    ///   - xpEarned: Total XP earned for this session
    ///   - bonusXP: Bonus XP earned (first session, streak, etc.)
    /// - Returns: The saved FocusSession
    func saveFocusSession(
        userId: UUID,
        durationMinutes: Int,
        xpEarned: Int,
        bonusXP: Int = 0
    ) async throws -> FocusSession {
        return try await withRetry {
            let newSession = NewFocusSession(
                userId: userId.uuidString,
                durationMinutes: durationMinutes,
                xpEarned: xpEarned,
                completedAt: Date(),
                bonusXpEarned: bonusXP
            )
            
            let response: [FocusSession] = try await self.client
                .from("focus_sessions")
                .insert(newSession)
                .select()
                .execute()
                .value
            
            guard let saved = response.first else {
                throw GamificationError.sessionSaveFailed
            }
            
            return saved
        }
    }
    
    /// Fetch user's focus session history
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - limit: Maximum number of sessions to fetch (default 50)
    /// - Returns: Array of FocusSession sorted by most recent first
    func fetchFocusSessions(userId: UUID, limit: Int = 50) async throws -> [FocusSession] {
        return try await client
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("completed_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }
    
    /// Check if this is the first session of the day for the user
    /// - Parameter userId: The user's UUID
    /// - Returns: True if no sessions completed today, false otherwise
    func isFirstSessionOfDay(userId: UUID) async throws -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let sessions: [FocusSession] = try await client
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("completed_at", value: formatter.string(from: today))
            .limit(1)
            .execute()
            .value
        
        return sessions.isEmpty
    }
    
    /// Get sessions for a specific date range (for stats)
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - startDate: Start of date range
    ///   - endDate: End of date range
    /// - Returns: Array of FocusSession within the date range
    func fetchSessionsInRange(userId: UUID, startDate: Date, endDate: Date) async throws -> [FocusSession] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return try await client
            .from("focus_sessions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("completed_at", value: formatter.string(from: startDate))
            .lte("completed_at", value: formatter.string(from: endDate))
            .order("completed_at", ascending: false)
            .execute()
            .value
    }
}

// MARK: - Streaks

extension SupabaseManager {
    
    /// Fetch the user's streak record
    /// - Parameter userId: The user's UUID
    /// - Returns: FocusStreak if found, nil otherwise
    func fetchStreak(userId: UUID) async throws -> FocusStreak? {
        // Use array query instead of .single() to handle empty results gracefully
        let response: [FocusStreak] = try await client
            .from("focus_streaks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return response.first
    }
    
    /// Create a new streak record for the user
    /// - Parameter userId: The user's UUID
    /// - Returns: Newly created FocusStreak
    func createStreak(userId: UUID) async throws -> FocusStreak {
        let newStreak = NewFocusStreak(
            userId: userId.uuidString,
            currentStreak: 1,
            longestStreak: 1,
            lastVisitDate: Date(),
            totalVisits: 1
        )
        
        let response: [FocusStreak] = try await client
            .from("focus_streaks")
            .insert(newStreak)
            .select()
            .execute()
            .value
        
        guard let created = response.first else {
            throw GamificationError.streakUpdateFailed
        }
        
        return created
    }
    
    /// Fetch or create streak record for user
    /// - Parameter userId: The user's UUID
    /// - Returns: Existing or new FocusStreak
    func fetchOrCreateStreak(userId: UUID) async throws -> FocusStreak {
        if let existing = try await fetchStreak(userId: userId) {
            return existing
        }
        return try await createStreak(userId: userId)
    }
    
    /// Update streak on app open - handles streak continuation or reset
    /// - Parameter userId: The user's UUID
    /// - Returns: Updated FocusStreak with streak status
    func updateStreak(userId: UUID) async throws -> FocusStreak {
        return try await withRetry {
            let streak = try await self.fetchOrCreateStreak(userId: userId)
            
            // Use UTC calendar for consistent date comparisons
            // Database stores dates as UTC midnight, so we must compare in UTC
            var utcCalendar = Calendar.current
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!
            let today = utcCalendar.startOfDay(for: Date())
            
            // If already visited today, no update needed
            if let lastVisit = streak.lastVisitDate {
                let lastVisitDay = utcCalendar.startOfDay(for: lastVisit)
                if lastVisitDay == today {
                    return streak
                }
                
                // Check if yesterday - continue streak
                let yesterday = utcCalendar.date(byAdding: .day, value: -1, to: today)!
                let isConsecutive = lastVisitDay == yesterday
                
                var newCurrentStreak: Int
                if isConsecutive {
                    newCurrentStreak = streak.currentStreak + 1
                } else {
                    // Streak broken - reset to 1
                    newCurrentStreak = 1
                }
                
                let newLongestStreak = max(streak.longestStreak, newCurrentStreak)
                
                struct StreakUpdate: Codable {
                    let current_streak: Int
                    let longest_streak: Int
                    let last_visit_date: Date
                    let total_visits: Int
                }
                
                let update = StreakUpdate(
                    current_streak: newCurrentStreak,
                    longest_streak: newLongestStreak,
                    last_visit_date: today,
                    total_visits: streak.totalVisits + 1
                )
                
                let response: [FocusStreak] = try await self.client
                    .from("focus_streaks")
                    .update(update)
                    .eq("user_id", value: userId.uuidString)
                    .select()
                    .execute()
                    .value
                
                guard let updated = response.first else {
                    throw GamificationError.streakUpdateFailed
                }
                
                return updated
            } else {
                // First ever visit - just update the date
                struct FirstVisitUpdate: Codable {
                    let last_visit_date: Date
                }
                
                let response: [FocusStreak] = try await self.client
                    .from("focus_streaks")
                    .update(FirstVisitUpdate(last_visit_date: today))
                    .eq("user_id", value: userId.uuidString)
                    .select()
                    .execute()
                    .value
                
                guard let updated = response.first else {
                    throw GamificationError.streakUpdateFailed
                }
                
                return updated
            }
        }
    }
}

// MARK: - Reference Data

extension SupabaseManager {
    
    /// Fetch all rank definitions from the database
    /// - Returns: Array of Rank sorted by display order
    func fetchRanks() async throws -> [Rank] {
        return try await client
            .from("ranks")
            .select()
            .order("display_order")
            .execute()
            .value
    }
    
    /// Fetch gamification settings (XP rates, etc.)
    /// - Returns: Array of GamificationSetting
    func fetchGamificationSettings() async throws -> [GamificationSetting] {
        return try await client
            .from("gamification_settings")
            .select()
            .execute()
            .value
    }
}
