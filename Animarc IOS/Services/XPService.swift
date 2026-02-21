//
//  XPService.swift
//  Animarc IOS
//
//  XP calculation logic (per-minute, bonuses)
//

import Foundation

/// Result of XP calculation for a focus session
struct XPCalculation {
    let baseXP: Int
    let sessionCompletionBonus: Int
    let firstSessionBonus: Int
    let streakBonus: Int
    let totalXP: Int
    
    /// Breakdown of XP earned for display
    var breakdown: [(label: String, amount: Int)] {
        var items: [(String, Int)] = []
        if baseXP > 0 {
            items.append(("Focus Time", baseXP))
        }
        if sessionCompletionBonus > 0 {
            items.append(("Session Complete", sessionCompletionBonus))
        }
        if firstSessionBonus > 0 {
            items.append(("First Session Bonus", firstSessionBonus))
        }
        if streakBonus > 0 {
            items.append(("Streak Bonus", streakBonus))
        }
        return items
    }
}

/// Service for calculating XP earned from focus sessions
final class XPService {
    
    // MARK: - Default XP Rates
    
    /// XP earned per minute of focus
    static var xpPerMinute: Int = 1
    
    /// Bonus XP for completing a session
    static var sessionCompletionBonus: Int = 25
    
    /// Bonus XP for first session of the day
    static var firstSessionBonus: Int = 50
    
    /// Bonus XP for maintaining a 7-day streak
    static var streak7DayBonus: Int = 200
    
    /// Bonus XP for a perfect week (7/7 days)
    static var perfectWeekBonus: Int = 500
    
    /// Minimum session duration (in minutes) to qualify for bonus XP
    static let minimumBonusSessionMinutes: Int = 5
    
    // MARK: - XP Calculation
    
    /// Calculate XP earned for a focus session
    /// - Parameters:
    ///   - durationMinutes: Duration of the focus session in minutes
    ///   - isSessionComplete: Whether the session was completed (not abandoned early)
    ///   - isFirstSessionOfDay: Whether this is the user's first session today
    ///   - currentStreak: Current streak days (for streak bonuses)
    /// - Returns: XPCalculation with breakdown of all XP earned
    static func calculateXP(
        durationMinutes: Int,
        isSessionComplete: Bool,
        isFirstSessionOfDay: Bool,
        currentStreak: Int = 0
    ) -> XPCalculation {
        // Base XP from time spent
        let baseXP = max(0, durationMinutes * xpPerMinute)
        
        let qualifiesForBonus = durationMinutes >= minimumBonusSessionMinutes
        
        // Session completion bonus (requires minimum session duration to prevent spam)
        let completionBonus = (isSessionComplete && qualifiesForBonus) ? sessionCompletionBonus : 0
        
        // First session of day bonus (requires minimum session duration)
        let firstBonus = (isFirstSessionOfDay && qualifiesForBonus) ? firstSessionBonus : 0
        
        // Streak bonus (7-day milestone)
        var streakBonus = 0
        if currentStreak > 0 && currentStreak % 7 == 0 && isFirstSessionOfDay {
            streakBonus = streak7DayBonus
        }
        
        let total = baseXP + completionBonus + firstBonus + streakBonus
        
        return XPCalculation(
            baseXP: baseXP,
            sessionCompletionBonus: completionBonus,
            firstSessionBonus: firstBonus,
            streakBonus: streakBonus,
            totalXP: total
        )
    }
    
    /// Update XP rates from gamification settings loaded from database
    /// - Parameter settings: Array of GamificationSetting from Supabase
    static func updateRates(from settings: [GamificationSetting]) {
        for setting in settings {
            switch setting.settingKey {
            case "xp_per_minute":
                if let value = setting.intValue {
                    xpPerMinute = value
                }
            case "session_completion_bonus":
                if let value = setting.intValue {
                    sessionCompletionBonus = value
                }
            case "first_session_bonus":
                if let value = setting.intValue {
                    firstSessionBonus = value
                }
            case "streak_7_day_bonus":
                if let value = setting.intValue {
                    streak7DayBonus = value
                }
            default:
                break
            }
        }
    }
}
