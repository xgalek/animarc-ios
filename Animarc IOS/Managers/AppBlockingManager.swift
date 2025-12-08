//
//  AppBlockingManager.swift
//  Animarc IOS
//
//  Manager for iOS Screen Time app blocking during focus sessions
//

import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

/// Manager for app blocking using iOS Screen Time API
@MainActor
final class AppBlockingManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AppBlockingManager()
    
    // MARK: - Published Properties
    
    /// Current authorization status
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    
    /// Whether blocking is currently active
    @Published var isBlockingActive: Bool = false
    
    /// Current settings
    @Published var settings: AppBlockingSettings
    
    // MARK: - Private Properties
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let managedSettingsStore = ManagedSettingsStore()
    
    // MARK: - Initialization
    
    private init() {
        self.settings = AppBlockingSettings.load()
        self.authorizationStatus = authorizationCenter.authorizationStatus
        
        // Observe authorization status changes
        Task {
            await observeAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request Screen Time authorization
    func requestAuthorization() async throws {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await MainActor.run {
                self.authorizationStatus = authorizationCenter.authorizationStatus
                self.settings.hasRequestedPermission = true
                self.settings.save()
            }
        } catch {
            await MainActor.run {
                self.authorizationStatus = authorizationCenter.authorizationStatus
                self.settings.hasRequestedPermission = true
                self.settings.save()
            }
            throw error
        }
    }
    
    /// Check if authorization is granted
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }
    
    /// Check if permission has been requested
    var hasRequestedPermission: Bool {
        settings.hasRequestedPermission
    }
    
    // MARK: - Blocking Control
    
    /// Selected applications to block (set via FamilyActivityPicker)
    /// This will contain all apps EXCEPT the ones user wants to allow
    private var selectedApplications = Set<ApplicationToken>()
    
    /// Start blocking apps during focus session
    func startBlocking() throws {
        guard isAuthorized else {
            throw AppBlockingError.notAuthorized
        }
        
        // Note: Screen Time API requires users to select apps via FamilyActivityPicker
        // We can't programmatically enumerate all apps. The blocking works by:
        // 1. User selects apps to block via FamilyActivityPicker (stored in selectedApplications)
        // 2. We apply those selections during focus sessions
        // 3. Phone and Messages are automatically allowed by iOS
        
        // Apply the selected applications to block
        if !selectedApplications.isEmpty {
            managedSettingsStore.shield.applications = selectedApplications
        } else {
            // If no apps selected yet, we can't block anything
            // This should be handled by ensuring apps are selected before first session
            print("AppBlockingManager: Warning - No apps selected for blocking")
        }
        
        // Store the blocking state
        isBlockingActive = true
        
        print("AppBlockingManager: Started blocking apps")
    }
    
    /// Set applications to block (called from FamilyActivityPicker selection)
    func setBlockedApplications(_ applications: Set<ApplicationToken>) {
        selectedApplications = applications
        // If blocking is active, update immediately
        if isBlockingActive {
            managedSettingsStore.shield.applications = selectedApplications
        }
    }
    
    /// Get currently selected applications for blocking
    var blockedApplications: Set<ApplicationToken> {
        selectedApplications
    }
    
    /// Stop blocking apps
    func stopBlocking() {
        // Clear all application shields
        managedSettingsStore.clearAllSettings()
        isBlockingActive = false
        
        print("AppBlockingManager: Stopped blocking apps")
    }
    
    /// Note: ApplicationToken cannot be serialized in Screen Time API
    /// The blocking state is managed via ManagedSettingsStore which persists automatically
    /// Selected applications are stored in memory via setBlockedApplications()
    
    /// Refresh authorization status
    func refreshAuthorizationStatus() {
        authorizationStatus = authorizationCenter.authorizationStatus
    }
    
    // MARK: - Private Methods
    
    private func observeAuthorizationStatus() async {
        // Monitor authorization status changes
        for await status in authorizationCenter.$authorizationStatus.values {
            await MainActor.run {
                self.authorizationStatus = status
            }
        }
    }
}

// MARK: - Errors

enum AppBlockingError: LocalizedError {
    case notAuthorized
    case tooManyApps(maxAllowed: Int)
    case invalidAppToken
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Screen Time permission is required to block apps during focus sessions."
        case .tooManyApps(let maxAllowed):
            return "You can only allow up to \(maxAllowed) additional apps."
        case .invalidAppToken:
            return "Invalid app token."
        }
    }
}
