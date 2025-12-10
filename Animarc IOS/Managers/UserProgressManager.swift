//
//  UserProgressManager.swift
//  Animarc IOS
//
//  Observable manager for user progress state in SwiftUI
//

import Foundation
import SwiftUI

/// Result of awarding XP after a session, includes level-up info
struct SessionReward {
    let xpCalculation: XPCalculation
    let didLevelUp: Bool
    let oldLevel: Int
    let newLevel: Int
    let didRankUp: Bool
    let oldRank: RankInfo?
    let newRank: RankInfo?
    let updatedProgress: UserProgress
}

/// Observable singleton manager for user progress and gamification state
@MainActor
final class UserProgressManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = UserProgressManager()
    
    // MARK: - Published Properties
    
    /// Current user progress (level, XP, rank, etc.)
    @Published var userProgress: UserProgress?
    
    /// Current streak information
    @Published var streak: FocusStreak?
    
    /// Recent focus sessions for history
    @Published var recentSessions: [FocusSession] = []
    
    /// Loading state for initial data fetch
    @Published var isLoading: Bool = false
    
    /// Error message if something goes wrong
    @Published var errorMessage: String?
    
    /// Pending level up info to be celebrated on HomeView
    @Published var pendingLevelUp: (oldLevel: Int, newLevel: Int)?
    
    /// Pending rank up info to be celebrated on HomeView
    @Published var pendingRankUp: (oldRank: RankInfo, newRank: RankInfo)?
    
    /// Pending item drop to be celebrated on HomeView
    @Published var pendingItemDrop: PortalItem?
    
    // MARK: - Computed Properties
    
    /// Current level (defaults to 1 if not loaded)
    var currentLevel: Int {
        userProgress?.currentLevel ?? 1
    }
    
    /// Current XP in level
    var currentXP: Int {
        userProgress?.currentXP ?? 0
    }
    
    /// Total XP earned
    var totalXP: Int64 {
        userProgress?.totalXPEarned ?? 0
    }
    
    /// Current rank code
    var currentRank: String {
        userProgress?.currentRank ?? "E"
    }
    
    /// Current rank info with color
    var currentRankInfo: RankInfo {
        RankService.getRankForLevel(currentLevel)
    }
    
    /// Total focus time in minutes
    var totalFocusMinutes: Int {
        userProgress?.totalFocusMinutes ?? 0
    }
    
    /// Total sessions completed
    var totalSessions: Int {
        userProgress?.totalSessionsCompleted ?? 0
    }
    
    /// Current streak days
    var currentStreak: Int {
        streak?.currentStreak ?? 0
    }
    
    /// Level progress information
    var levelProgress: LevelProgress {
        LevelService.getLevelProgress(totalXP: Int(totalXP))
    }
    
    /// Formatted total focus time (e.g., "24h 30m")
    var formattedTotalFocusTime: String {
        let hours = totalFocusMinutes / 60
        let minutes = totalFocusMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Data Loading
    
    /// Load all user progress data on app launch
    func loadProgress() async {
        guard let userId = await getCurrentUserId() else {
            print("UserProgressManager: No authenticated user")
            errorMessage = "Not authenticated. Please sign in again."
            ErrorManager.shared.showError("Failed to load progress: Not authenticated")
            return
        }
        
        print("UserProgressManager: Loading progress for user \(userId)")
        isLoading = true
        errorMessage = nil
        
        var criticalFailures = 0
        
        // Load user progress
        do {
            if let progress = try await SupabaseManager.shared.fetchUserProgress(userId: userId) {
                print("UserProgressManager: Found existing progress - Level \(progress.currentLevel)")
                self.userProgress = progress
            } else {
                print("UserProgressManager: No progress found, creating new record...")
                self.userProgress = try await SupabaseManager.shared.createUserProgress(userId: userId)
                print("UserProgressManager: Created new progress record")
            }
        } catch {
            criticalFailures += 1
            print("UserProgressManager: Failed to load/create progress: \(error)")
            logError("loadProgress", error: error, context: ["userId": userId.uuidString])
            
            // Check if session expired
            if SupabaseManager.shared.handleSessionError(error) {
                errorMessage = "Session expired. Please sign in again."
                ErrorManager.shared.showError("Your session has expired. Please sign in again.")
            } else {
                self.userProgress = nil
            }
        }
        
        // Load streak (separate try-catch so one failure doesn't block others)
        do {
            self.streak = try await SupabaseManager.shared.updateStreak(userId: userId)
            print("UserProgressManager: Streak loaded - \(streak?.currentStreak ?? 0) days")
        } catch {
            print("UserProgressManager: Failed to load streak: \(error)")
            logError("loadStreak", error: error, context: ["userId": userId.uuidString])
            self.streak = nil
            // Non-critical, don't show error toast
        }
        
        // Load recent sessions (separate try-catch)
        do {
            self.recentSessions = try await SupabaseManager.shared.fetchFocusSessions(userId: userId, limit: 20)
            print("UserProgressManager: Loaded \(recentSessions.count) recent sessions")
        } catch {
            print("UserProgressManager: Failed to load sessions: \(error)")
            logError("loadSessions", error: error, context: ["userId": userId.uuidString])
            self.recentSessions = []
            // Non-critical, don't show error toast
        }
        
        // Load and apply gamification settings (non-critical)
        do {
            let settings = try await SupabaseManager.shared.fetchGamificationSettings()
            XPService.updateRates(from: settings)
            print("UserProgressManager: Applied gamification settings")
        } catch {
            print("UserProgressManager: Failed to load gamification settings (using defaults): \(error)")
            logError("loadGamificationSettings", error: error, context: ["userId": userId.uuidString])
            // Non-critical, using defaults
        }
        
        // Show error if critical operations failed
        if criticalFailures > 0 && userProgress == nil {
            errorMessage = "Failed to load your progress. Pull down to retry."
            ErrorManager.shared.showError("Failed to load progress. Pull down to refresh.")
        }
        
        isLoading = false
    }
    
    /// Refresh user progress (called after returning to app)
    func refreshProgress() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            if let progress = try await SupabaseManager.shared.fetchUserProgress(userId: userId) {
                self.userProgress = progress
            }
        } catch {
            print("Failed to refresh progress: \(error)")
            logError("refreshProgress", error: error, context: ["userId": userId.uuidString])
            ErrorManager.shared.showWarning("Failed to refresh progress. Your data may be out of date.")
        }
        
        do {
            self.streak = try await SupabaseManager.shared.updateStreak(userId: userId)
        } catch {
            print("Failed to refresh streak: \(error)")
            logError("refreshStreak", error: error, context: ["userId": userId.uuidString])
            // Non-critical, don't show error
        }
    }
    
    // MARK: - Session Completion
    
    /// Award XP after completing a focus session
    /// - Parameter durationMinutes: Duration of the completed session in minutes
    /// - Returns: SessionReward with XP breakdown and level-up info
    func awardXP(durationMinutes: Int) async -> SessionReward? {
        guard let userId = await getCurrentUserId() else {
            print("awardXP: Not authenticated")
            errorMessage = "Not authenticated"
            logError("awardXP", error: GamificationError.notAuthenticated, context: ["durationMinutes": durationMinutes])
            ErrorManager.shared.showError("Failed to award XP: Not authenticated. Please sign in again.")
            return nil
        }
        
        // If no progress exists yet, try to create one first
        if userProgress == nil {
            print("awardXP: No user progress, attempting to create...")
            do {
                self.userProgress = try await SupabaseManager.shared.createUserProgress(userId: userId)
            } catch {
                print("awardXP: Failed to create user progress: \(error)")
                errorMessage = "Failed to create user profile"
                logError("awardXP_createProgress", error: error, context: ["userId": userId.uuidString, "durationMinutes": durationMinutes])
                ErrorManager.shared.showError("Failed to create user profile. Please try again.")
                return nil
            }
        }
        
        guard let currentProgress = userProgress else {
            print("awardXP: Progress still nil after creation attempt")
            errorMessage = "Progress not loaded"
            ErrorManager.shared.showError("Progress not loaded. Please restart the app.")
            return nil
        }
        
        do {
            // Check if first session of day (default to true if check fails)
            var isFirstSession = true
            do {
                isFirstSession = try await SupabaseManager.shared.isFirstSessionOfDay(userId: userId)
            } catch {
                print("awardXP: Failed to check first session, assuming true: \(error)")
                logError("awardXP_checkFirstSession", error: error, context: ["userId": userId.uuidString])
            }
            
            // Calculate XP
            let xpCalc = XPService.calculateXP(
                durationMinutes: durationMinutes,
                isSessionComplete: true,
                isFirstSessionOfDay: isFirstSession,
                currentStreak: currentStreak
            )
            
            print("awardXP: Calculated XP - base: \(xpCalc.baseXP), total: \(xpCalc.totalXP)")
            
            // Save old values for comparison
            let oldLevel = currentProgress.currentLevel
            let oldTotalXP = Int(currentProgress.totalXPEarned)
            
            // Save session to database
            do {
                _ = try await SupabaseManager.shared.saveFocusSession(
                    userId: userId,
                    durationMinutes: durationMinutes,
                    xpEarned: xpCalc.totalXP,
                    bonusXP: xpCalc.firstSessionBonus + xpCalc.streakBonus
                )
                print("awardXP: Session saved to database")
            } catch {
                print("awardXP: Failed to save session (continuing anyway): \(error)")
                logError("awardXP_saveSession", error: error, context: [
                    "userId": userId.uuidString,
                    "durationMinutes": durationMinutes,
                    "xpEarned": xpCalc.totalXP
                ])
                // Continue anyway - XP update is more important
                ErrorManager.shared.showWarning("Session saved locally but failed to sync. It will sync when connection is restored.")
            }
            
            // Update user progress with new XP
            let updatedProgress = try await SupabaseManager.shared.updateXP(
                userId: userId,
                xpToAdd: xpCalc.totalXP,
                focusMinutesIncrement: durationMinutes,
                sessionsIncrement: 1
            )
            
            print("awardXP: Progress updated - New total XP: \(updatedProgress.totalXPEarned)")
            
            // Update local state
            self.userProgress = updatedProgress
            
            // Refresh sessions list (non-critical)
            do {
                self.recentSessions = try await SupabaseManager.shared.fetchFocusSessions(userId: userId, limit: 20)
            } catch {
                print("awardXP: Failed to refresh sessions list: \(error)")
                logError("awardXP_refreshSessions", error: error, context: ["userId": userId.uuidString])
            }
            
            // Check for level up
            let newTotalXP = oldTotalXP + xpCalc.totalXP
            let levelUpResult = LevelService.checkLevelUp(oldXP: oldTotalXP, newXP: newTotalXP)
            let didLevelUp = levelUpResult != nil
            let newLevel = levelUpResult?.newLevel ?? oldLevel
            
            // Check for rank up
            var didRankUp = false
            var oldRankInfo: RankInfo?
            var newRankInfo: RankInfo?
            
            if didLevelUp {
                if let rankUp = RankService.checkForRankUp(oldLevel: oldLevel, newLevel: newLevel) {
                    didRankUp = true
                    oldRankInfo = rankUp.oldRank
                    newRankInfo = rankUp.newRank
                }
            }
            
            // Store pending rewards for celebration on HomeView
            if didLevelUp {
                self.pendingLevelUp = (oldLevel: oldLevel, newLevel: newLevel)
            }
            
            if didRankUp, let oldRank = oldRankInfo, let newRank = newRankInfo {
                self.pendingRankUp = (oldRank: oldRank, newRank: newRank)
            }
            
            return SessionReward(
                xpCalculation: xpCalc,
                didLevelUp: didLevelUp,
                oldLevel: oldLevel,
                newLevel: newLevel,
                didRankUp: didRankUp,
                oldRank: oldRankInfo,
                newRank: newRankInfo,
                updatedProgress: updatedProgress
            )
            
        } catch {
            print("awardXP: Failed to award XP: \(error)")
            errorMessage = error.localizedDescription
            logError("awardXP", error: error, context: [
                "userId": userId.uuidString,
                "durationMinutes": durationMinutes,
                "currentLevel": currentProgress.currentLevel,
                "currentXP": currentProgress.totalXPEarned
            ])
            
            // Check if session expired
            if SupabaseManager.shared.handleSessionError(error) {
                ErrorManager.shared.showError("Your session expired. Please sign in again to continue.")
            } else {
                ErrorManager.shared.showError("Failed to award XP: \(error.localizedDescription). Please try again.")
            }
            
            return nil
        }
    }
    
    // MARK: - Stats Helpers
    
    /// Get sessions for today
    func getSessionsToday() async -> [FocusSession] {
        guard let userId = await getCurrentUserId() else { return [] }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            return try await SupabaseManager.shared.fetchSessionsInRange(
                userId: userId,
                startDate: today,
                endDate: tomorrow
            )
        } catch {
            print("Failed to get today's sessions: \(error)")
            return []
        }
    }
    
    /// Get sessions for the past week
    func getSessionsThisWeek() async -> [FocusSession] {
        guard let userId = await getCurrentUserId() else { return [] }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            return try await SupabaseManager.shared.fetchSessionsInRange(
                userId: userId,
                startDate: weekAgo,
                endDate: tomorrow
            )
        } catch {
            print("Failed to get this week's sessions: \(error)")
            return []
        }
    }
    
    /// Calculate stats for a set of sessions
    func calculateStats(sessions: [FocusSession]) -> (totalMinutes: Int, totalXP: Int, avgMinutes: Int, longestMinutes: Int) {
        guard !sessions.isEmpty else {
            return (0, 0, 0, 0)
        }
        
        let totalMinutes = sessions.reduce(0) { $0 + $1.durationMinutes }
        let totalXP = sessions.reduce(0) { $0 + $1.xpEarned }
        let avgMinutes = totalMinutes / sessions.count
        let longestMinutes = sessions.map { $0.durationMinutes }.max() ?? 0
        
        return (totalMinutes, totalXP, avgMinutes, longestMinutes)
    }
    
    // MARK: - Private Helpers
    
    /// Get current authenticated user ID
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.user.id
        } catch {
            print("Failed to get user ID: \(error)")
            return nil
        }
    }
    
    /// Clear all data on sign out
    func clearData() {
        userProgress = nil
        streak = nil
        recentSessions = []
        errorMessage = nil
        clearPendingRewards()
    }
    
    /// Clear pending rewards after they've been shown
    func clearPendingRewards() {
        pendingLevelUp = nil
        pendingRankUp = nil
        pendingItemDrop = nil
    }
    
    // MARK: - Error Logging
    
    /// Log error with context for debugging and Sentry integration
    private func logError(_ operation: String, error: Error, context: [String: Any] = [:]) {
        var logContext: [String: Any] = [
            "operation": operation,
            "error": error.localizedDescription,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Add custom context
        logContext.merge(context) { (_, new) in new }
        
        // Add error type info
        if let gamificationError = error as? GamificationError {
            logContext["errorType"] = String(describing: gamificationError)
            logContext["isRetryable"] = gamificationError.isRetryable
            logContext["isAuthError"] = gamificationError.isAuthError
        }
        
        // Log to console (will be replaced with Sentry in step 2)
        print("ERROR [\(operation)]: \(error.localizedDescription)")
        print("Context: \(logContext)")
        
        // TODO: Send to Sentry when integrated
        // SentrySDK.capture(error: error) { scope in
        //     scope.setContext(value: logContext, key: "operation")
        // }
    }
}
