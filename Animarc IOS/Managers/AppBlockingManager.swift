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
    
    /// Selected activity for displaying app icons
    @Published var selectedActivity: FamilyActivitySelection = FamilyActivitySelection()
    
    // MARK: - Private Properties
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let managedSettingsStore = ManagedSettingsStore()
    
    // MARK: - Initialization
    
    private init() {
        self.settings = AppBlockingSettings.load()
        self.authorizationStatus = authorizationCenter.authorizationStatus
        
        print("🏗️ AppBlockingManager initialized")
        print("   📋 Initial authorizationStatus: \(authorizationStatus)")
        print("   📊 Initial shield.applicationCategories: \(String(describing: managedSettingsStore.shield.applicationCategories))")
        print("   📊 Initial shield.applications: \(String(describing: managedSettingsStore.shield.applications))")
        
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
        let authorized = authorizationStatus == .approved
        print("🔐 AppBlockingManager.isAuthorized: \(authorized) (status: \(authorizationStatus))")
        return authorized
    }
    
    /// Check if permission has been requested
    var hasRequestedPermission: Bool {
        settings.hasRequestedPermission
    }
    
    // MARK: - Blocking Control
    
    /// Selected applications to ALLOW during focus (set via FamilyActivityPicker)
    /// All apps NOT in this set will be blocked during focus sessions
    /// Phone and Messages are automatically allowed by iOS
    private var selectedApplications = Set<ApplicationToken>()
    
    /// Start blocking apps during focus session
    func startBlocking() throws {
        print("🚀 AppBlockingManager.startBlocking() called")
        print("   📋 Current authorizationStatus: \(authorizationStatus)")
        print("   📋 AuthorizationCenter status: \(authorizationCenter.authorizationStatus)")
        
        guard isAuthorized else {
            print("❌ AppBlockingManager: NOT AUTHORIZED - throwing error")
            throw AppBlockingError.notAuthorized
        }
        
        print("✅ AppBlockingManager: Authorization confirmed, applying shields...")
        
        // Block ALL apps - this should block everything except system essentials
        // Phone and Messages are automatically allowed by iOS
        
        // Log current state before applying
        print("   📊 BEFORE - shield.applicationCategories: \(String(describing: managedSettingsStore.shield.applicationCategories))")
        print("   📊 BEFORE - shield.applications: \(String(describing: managedSettingsStore.shield.applications))")
        
        // Apply category blocking - block ALL categories
        managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
        print("   ✅ SET shield.applicationCategories = .all()")
        
        // Clear any specific app exceptions (block everything)
        // Note: If we had an allowlist, we'd set it here
        managedSettingsStore.shield.applications = nil
        print("   ✅ SET shield.applications = nil (no exceptions)")
        
        // Log state after applying
        print("   📊 AFTER - shield.applicationCategories: \(String(describing: managedSettingsStore.shield.applicationCategories))")
        print("   📊 AFTER - shield.applications: \(String(describing: managedSettingsStore.shield.applications))")
        
        // Store the blocking state
        isBlockingActive = true
        
        print("🎯 AppBlockingManager: Blocking ACTIVE - all app categories should be shielded")
        print("   ℹ️ Phone, Messages, FaceTime remain accessible (iOS system behavior)")
    }
    
    /// Set applications to ALLOW (called from FamilyActivityPicker selection)
    /// These apps will be accessible during focus, all others will be blocked
    func setBlockedApplications(_ applications: Set<ApplicationToken>) {
        selectedApplications = applications
        // If blocking is active, update immediately
        if isBlockingActive {
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
            managedSettingsStore.shield.applications = selectedApplications
        }
    }
    
    /// Set applications to ALLOW with full selection (for icon display)
    /// These apps will be accessible during focus, all others will be blocked
    func setBlockedApplications(_ applications: Set<ApplicationToken>, selection: FamilyActivitySelection) {
        selectedApplications = applications
        selectedActivity = selection
        // If blocking is active, update immediately
        if isBlockingActive {
            managedSettingsStore.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
            managedSettingsStore.shield.applications = selectedApplications
        }
    }
    
    /// Get currently allowed applications (allowlist)
    /// Note: Despite the name "blockedApplications", this actually returns the allowlist
    /// This property name is kept for backward compatibility with existing UI code
    var blockedApplications: Set<ApplicationToken> {
        selectedApplications
    }
    
    /// Stop blocking apps
    func stopBlocking() {
        print("🛑 AppBlockingManager.stopBlocking() called")
        print("   📊 BEFORE - shield.applicationCategories: \(String(describing: managedSettingsStore.shield.applicationCategories))")
        print("   📊 BEFORE - shield.applications: \(String(describing: managedSettingsStore.shield.applications))")
        
        // Clear all application shields
        managedSettingsStore.clearAllSettings()
        isBlockingActive = false
        
        print("   📊 AFTER - shield.applicationCategories: \(String(describing: managedSettingsStore.shield.applicationCategories))")
        print("   📊 AFTER - shield.applications: \(String(describing: managedSettingsStore.shield.applications))")
        print("✅ AppBlockingManager: All shields cleared - apps unblocked")
    }
    
    /// Note: ApplicationToken cannot be serialized in Screen Time API
    /// The blocking state is managed via ManagedSettingsStore which persists automatically
    /// Allowed applications (allowlist) are stored in memory via setBlockedApplications()
    
    /// Refresh authorization status
    func refreshAuthorizationStatus() {
        let oldStatus = authorizationStatus
        authorizationStatus = authorizationCenter.authorizationStatus
        print("🔄 AppBlockingManager.refreshAuthorizationStatus()")
        print("   📋 Old status: \(oldStatus)")
        print("   📋 New status: \(authorizationStatus)")
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
