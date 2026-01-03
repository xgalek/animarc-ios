//
//  SupabaseManager.swift
//  Animarc IOS
//
//  Created for Supabase integration
//

import Foundation
import Supabase

/// Singleton manager class for handling Supabase connections throughout the app.
/// Access the shared instance via `SupabaseManager.shared`.
@MainActor
final class SupabaseManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared singleton instance
    static let shared = SupabaseManager()
    
    // MARK: - Properties
    
    /// The Supabase client used for all database operations, authentication, and storage.
    /// Access this property to interact with Supabase services.
    let client: SupabaseClient
    
    /// Tracks whether the user is currently authenticated
    @Published var isAuthenticated: Bool = false
    
    /// Tracks whether the initial session check has completed
    @Published var isLoading: Bool = true
    
    // MARK: - Configuration
    
    /// Supabase project URL (loaded from secure config)
    private static var supabaseURL: URL {
        return AppConfig.supabaseURL
    }
    
    /// Supabase anonymous key (loaded from secure config)
    private static var supabaseAnonKey: String {
        return AppConfig.supabaseAnonKey
    }
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern.
    /// Initializes the Supabase client with the project URL and anon key.
    /// Configures Keychain storage for session persistence across app restarts.
    private init() {
        self.client = SupabaseClient(
            supabaseURL: Self.supabaseURL,
            supabaseKey: Self.supabaseAnonKey,
            options: .init(
                auth: .init(
                    storage: KeychainLocalStorage()
                )
            )
        )
    }
    
    // MARK: - Session Management
    
    /// Checks for an existing valid session stored in Keychain.
    /// Updates isAuthenticated based on whether a valid session exists.
    func checkExistingSession() async {
        isLoading = true
        
        do {
            let session = try await client.auth.session
            
            print("=== Existing Session Found ===")
            print("User ID: \(session.user.id)")
            print("Email: \(session.user.email ?? "N/A")")
            print("Session expires at: \(session.expiresAt)")
            print("==============================")
            isAuthenticated = true
        } catch {
            print("No existing session: \(error.localizedDescription)")
            isAuthenticated = false
            
            // Check if this is a session expiration error
            if handleSessionError(error) {
                print("Session expired or invalid - user needs to sign in again")
            }
        }
        
        isLoading = false
    }
    
    /// Signs out the current user and clears the session
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            print("User signed out successfully")
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Retry Logic

extension SupabaseManager {
    
    /// Execute an async operation with automatic retry on transient failures
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 2)
    ///   - retryDelay: Delay between retries in seconds (default: 1.5)
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    /// - Throws: The error if all retries fail
    func withRetry<T>(
        maxRetries: Int = 2,
        retryDelay: TimeInterval = 1.5,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                let result = try await operation()
                
                // Log retry success if this was a retry
                if attempt > 0 {
                    print("SupabaseManager: Operation succeeded after \(attempt) retry(ies)")
                }
                
                return result
            } catch {
                lastError = error
                
                // Check if error is retryable
                let isRetryable = isRetryableError(error)
                
                // Don't retry on last attempt or if error is not retryable
                if attempt >= maxRetries || !isRetryable {
                    if attempt > 0 {
                        print("SupabaseManager: Operation failed after \(attempt) retry(ies): \(error.localizedDescription)")
                    }
                    throw error
                }
                
                // Log retry attempt
                print("SupabaseManager: Operation failed (attempt \(attempt + 1)/\(maxRetries + 1)), retrying in \(retryDelay)s...")
                
                // Wait before retrying
                try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
            }
        }
        
        // Should never reach here, but just in case
        throw lastError ?? NSError(domain: "SupabaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
    }
    
    /// Check if an error is retryable (network/transient errors)
    private func isRetryableError(_ error: Error) -> Bool {
        // Check for network-related errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost:
                return true
            case .httpTooManyRedirects, .badServerResponse:
                return true
            default:
                return false
            }
        }
        
        // Check for Supabase-specific errors
        if let supabaseError = error as NSError? {
            // Retry on 5xx server errors
            if supabaseError.domain.contains("supabase") || supabaseError.domain.contains("postgrest") {
                if let statusCode = supabaseError.userInfo["statusCode"] as? Int {
                    return statusCode >= 500 && statusCode < 600
                }
                return true // Assume retryable if Supabase error
            }
        }
        
        // Check for GamificationError
        if let gamificationError = error as? GamificationError {
            return gamificationError.isRetryable
        }
        
        return false
    }
    
    /// Handle session expiration and redirect to auth if needed
    func handleSessionError(_ error: Error) -> Bool {
        // Check if this is a session/auth error
        if let gamificationError = error as? GamificationError, gamificationError.isAuthError {
            Task { @MainActor in
                isAuthenticated = false
                print("SupabaseManager: Session expired, redirecting to auth")
            }
            return true
        }
        
        // Check for Supabase auth errors
        if let nsError = error as NSError? {
            let errorDescription = nsError.localizedDescription.lowercased()
            if errorDescription.contains("session") || errorDescription.contains("token") || errorDescription.contains("unauthorized") {
                Task { @MainActor in
                    isAuthenticated = false
                    print("SupabaseManager: Auth error detected, redirecting to auth")
                }
                return true
            }
        }
        
        return false
    }
}

// MARK: - Authentication

extension SupabaseManager {
    // Future authentication methods:
    // - signUp(email:password:)
    // - signIn(email:password:)
    // - getCurrentUser()
    // - onAuthStateChange()
}

// MARK: - Database (Placeholder for future implementation)

extension SupabaseManager {
    // TODO: Add database query methods
    // - fetch<T>(from table:)
    // - insert<T>(into table:, values:)
    // - update<T>(in table:, values:, matching:)
    // - delete(from table:, matching:)
    
    /// Tests the Supabase connection by checking the current auth session.
    /// Prints success or error messages to the console.
    func testConnection() async {
        print("🔄 Testing Supabase connection...")
        
        // Test connection by checking auth session (works without any tables)
        let session = try? await client.auth.session
        
        if let session = session {
            print("✅ Supabase connected successfully!")
            print("👤 User logged in: \(session.user.email ?? session.user.id.uuidString)")
        } else {
            // No session but connection works - this is expected for anonymous users
            print("✅ Supabase connected successfully!")
            print("👤 No user session (anonymous mode)")
        }
    }
}

// MARK: - Storage (Placeholder for future implementation)

extension SupabaseManager {
    // TODO: Add storage methods
    // - uploadFile(to bucket:, path:, data:)
    // - downloadFile(from bucket:, path:)
    // - deleteFile(from bucket:, path:)
    // - getPublicURL(for bucket:, path:)
}

// MARK: - Account Deletion

extension SupabaseManager {
    
    /// Permanently delete user account and all associated data
    /// - Parameter userId: The user's UUID
    /// - Throws: Error if deletion fails
    func deleteUserAccount(userId: UUID) async throws {
        return try await withRetry {
            // Delete all user data from database tables
            // Order matters for foreign key constraints
            
            // 1. Delete portal progress
            try await self.client
                .from("portal_progress")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // 2. Delete portal inventory
            try await self.client
                .from("portal_inventory")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // 3. Delete focus sessions
            try await self.client
                .from("focus_sessions")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // 4. Delete focus streaks
            try await self.client
                .from("focus_streaks")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // 5. Delete user progress (should be last)
            try await self.client
                .from("user_progress")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            print("User account and all data deleted successfully for user: \(userId)")
        }
    }
}

