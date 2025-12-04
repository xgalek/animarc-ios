//
//  GamificationError.swift
//  Animarc IOS
//
//  Custom error types for gamification operations
//

import Foundation

enum GamificationError: LocalizedError {
    case userProgressNotFound
    case notAuthenticated
    case sessionSaveFailed
    case streakUpdateFailed
    case invalidUserId
    
    var errorDescription: String? {
        switch self {
        case .userProgressNotFound:
            return "User progress record not found"
        case .notAuthenticated:
            return "User is not authenticated"
        case .sessionSaveFailed:
            return "Failed to save focus session"
        case .streakUpdateFailed:
            return "Failed to update streak"
        case .invalidUserId:
            return "Invalid user ID"
        }
    }
}

