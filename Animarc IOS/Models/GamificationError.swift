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
    
    // Network-related errors
    case networkTimeout
    case noConnection
    case serverError(statusCode: Int)
    case requestFailed
    
    // Data sync errors
    case dataConflict
    case staleData
    case syncFailed
    
    // Session-related errors
    case sessionExpired
    case invalidSession
    case tokenRefreshFailed
    
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
        case .networkTimeout:
            return "Request timed out. Please check your connection and try again."
        case .noConnection:
            return "No internet connection. Please check your network settings."
        case .serverError(let statusCode):
            return "Server error occurred (Code: \(statusCode)). Please try again later."
        case .requestFailed:
            return "Request failed. Please try again."
        case .dataConflict:
            return "Data conflict detected. Your progress may be out of sync."
        case .staleData:
            return "Data is out of date. Please refresh."
        case .syncFailed:
            return "Failed to sync data. Please check your connection."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .invalidSession:
            return "Invalid session. Please sign in again."
        case .tokenRefreshFailed:
            return "Failed to refresh session. Please sign in again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .userProgressNotFound, .invalidUserId:
            return "Please try restarting the app."
        case .notAuthenticated, .sessionExpired, .invalidSession, .tokenRefreshFailed:
            return "Please sign in again to continue."
        case .networkTimeout, .noConnection, .requestFailed:
            return "Check your internet connection and try again."
        case .serverError:
            return "The server is experiencing issues. Please try again in a few moments."
        case .dataConflict, .staleData, .syncFailed:
            return "Pull down to refresh your data."
        case .sessionSaveFailed, .streakUpdateFailed:
            return "Your progress is saved locally. It will sync when connection is restored."
        }
    }
    
    /// Check if this error should trigger a retry
    var isRetryable: Bool {
        switch self {
        case .networkTimeout, .noConnection, .requestFailed, .serverError:
            return true
        case .sessionSaveFailed, .streakUpdateFailed, .syncFailed:
            return true
        default:
            return false
        }
    }
    
    /// Check if this is an authentication error
    var isAuthError: Bool {
        switch self {
        case .notAuthenticated, .sessionExpired, .invalidSession, .tokenRefreshFailed:
            return true
        default:
            return false
        }
    }
}

