//
//  Animarc_IOSApp.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import UIKit

@main
struct Animarc_IOSApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var progressManager = UserProgressManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Validate configuration on app startup (only in debug to catch missing config early)
        #if DEBUG
        AppConfig.validateConfiguration()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if supabaseManager.isLoading {
                    // Show loading screen while checking session
                    ZStack {
                        Color(hex: "#1A2332")
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            Text("Animarc")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            ProgressView()
                                .tint(.white)
                        }
                    }
                } else if supabaseManager.isAuthenticated {
                    // User is authenticated - skip onboarding, go directly to MainTabView
                    MainTabView()
                        .environmentObject(progressManager)
                        .task {
                            // Load user progress after authentication
                            await progressManager.loadProgress()
                        }
                } else if hasCompletedOnboarding {
                    // Onboarding completed but not authenticated - show AuthView
                    AuthView(isAuthenticated: $supabaseManager.isAuthenticated)
                } else {
                    // Show onboarding (with "Already have an account" option)
                    OnboardingView()
                        .environmentObject(progressManager)
                }
            }
            .task {
                // Check for existing session first (this persists via Keychain)
                await supabaseManager.checkExistingSession()
                // Ensure app blocking is in a clean state on launch
                // Blocks will be applied when user starts a focus session
                AppBlockingManager.shared.stopBlocking()
                
                // Identify RevenueCat user with Supabase user ID after auth
                if supabaseManager.isAuthenticated {
                    do {
                        let userId = try await supabaseManager.client.auth.session.user.id.uuidString
                        try await revenueCatManager.identifyUser(userId: userId)
                    } catch {
                        print("RevenueCat identification error: \(error.localizedDescription)")
                    }
                }
            }
            .onChange(of: supabaseManager.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated {
                    // Clear progress data on sign out
                    progressManager.clearData()
                    // Logout from RevenueCat when user signs out
                    Task {
                        try? await revenueCatManager.logout()
                    }
                } else {
                    // Identify user when authenticated
                    Task {
                        do {
                            let userId = try await supabaseManager.client.auth.session.user.id.uuidString
                            try await revenueCatManager.identifyUser(userId: userId)
                        } catch {
                            print("RevenueCat identification error: \(error.localizedDescription)")
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Handle app lifecycle changes
                handleScenePhaseChange(newPhase)
            }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Ensure idle timer is reset when app goes to background
            UIApplication.shared.isIdleTimerDisabled = false
            break
        case .inactive:
            // App going to inactive - ensure blocks are maintained
            // ManagedSettingsStore persists across app lifecycle
            break
        case .active:
            // App becoming active - refresh authorization status
            Task { @MainActor in
                AppBlockingManager.shared.refreshAuthorizationStatus()
            }
        @unknown default:
            break
        }
    }
}
