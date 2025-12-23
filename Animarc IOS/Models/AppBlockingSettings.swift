//
//  AppBlockingSettings.swift
//  Animarc IOS
//
//  Settings model for app blocking feature
//

import Foundation

/// Settings for app blocking feature with persistence
struct AppBlockingSettings: Codable {
    /// Whether app blocking is enabled
    var isEnabled: Bool
    
    /// List of allowed app tokens (beyond Phone/Messages/system apps)
    /// Maximum of 2 apps allowed
    var allowedApps: [String]
    
    /// Whether permission has been requested at least once
    var hasRequestedPermission: Bool
    
    /// Maximum number of additional apps user can allow (beyond system apps)
    static let maxAllowedApps = 2
    
    /// Default settings
    static let `default` = AppBlockingSettings(
        isEnabled: true,
        allowedApps: [],
        hasRequestedPermission: false
    )
    
    /// Check if user can add more apps
    var canAddMoreApps: Bool {
        allowedApps.count < Self.maxAllowedApps
    }
    
    /// Validate that allowed apps count doesn't exceed limit
    mutating func validateAppLimit() {
        if allowedApps.count > Self.maxAllowedApps {
            allowedApps = Array(allowedApps.prefix(Self.maxAllowedApps))
        }
    }
}

// MARK: - Persistence

extension AppBlockingSettings {
    private static let userDefaultsKey = "AppBlockingSettings"
    
    /// Load settings from UserDefaults
    static func load() -> AppBlockingSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(AppBlockingSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    /// Save settings to UserDefaults
    func save() {
        var validated = self
        validated.validateAppLimit()
        
        if let data = try? JSONEncoder().encode(validated) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    /// Reset to default settings
    static func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
