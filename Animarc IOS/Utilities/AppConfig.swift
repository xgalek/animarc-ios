//
//  AppConfig.swift
//  Animarc IOS
//
//  Secure configuration manager that reads from build settings
//  Secrets are stored in Xcode build settings, not in source code
//

import Foundation

/// Secure configuration manager for app secrets and API keys
/// Reads values from Info.plist (which gets populated from build settings)
enum AppConfig {
    
    // MARK: - Supabase Configuration
    
    /// Supabase project URL
    static var supabaseURL: URL {
        guard let urlString = getValue(for: "SUPABASE_URL"),
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL must be set in build settings")
        }
        return url
    }
    
    /// Supabase anonymous key
    static var supabaseAnonKey: String {
        guard let key = getValue(for: "SUPABASE_ANON_KEY") else {
            fatalError("SUPABASE_ANON_KEY must be set in build settings")
        }
        return key
    }
    
    // MARK: - Google Sign-In Configuration
    
    /// Google OAuth Client ID
    static var googleClientID: String {
        guard let clientID = getValue(for: "GOOGLE_CLIENT_ID") else {
            fatalError("GOOGLE_CLIENT_ID must be set in build settings")
        }
        return clientID
    }
    
    // MARK: - RevenueCat Configuration
    
    /// RevenueCat API Key
    static var revenueCatAPIKey: String {
        guard let apiKey = getValue(for: "REVENUECAT_API_KEY") else {
            fatalError("REVENUECAT_API_KEY must be set in build settings")
        }
        return apiKey
    }
    
    // MARK: - Helper Methods
    
    /// Get value from Info.plist (populated from build settings)
    private static func getValue(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
    
    /// Validate that all required configuration values are present
    /// Call this during app startup to fail fast if config is missing
    static func validateConfiguration() {
        _ = supabaseURL
        _ = supabaseAnonKey
        _ = googleClientID
        _ = revenueCatAPIKey
    }
}

