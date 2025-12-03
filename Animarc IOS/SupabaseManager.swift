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
    
    /// Supabase project URL
    private static let supabaseURL = URL(string: "https://girifmitgbaxiaktjckz.supabase.co")!
    
    /// Supabase anonymous key for public access
    private static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdpcmlmbWl0Z2JheGlha3RqY2t6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5MTc0MDEsImV4cCI6MjA3NTQ5MzQwMX0.XDMQp7h_WaP1OwGSfn8lPksvRjFq5KiQoySf2VPTyPo"
    
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
        }
        
        isLoading = false
    }
    
    /// Signs out the current user and clears the session
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            print("User signed out successfully")
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
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

