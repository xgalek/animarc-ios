//
//  Animarc_IOSApp.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

@main
struct Animarc_IOSApp: App {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var progressManager = UserProgressManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
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
                    MainTabView()
                        .environmentObject(progressManager)
                        .task {
                            // Load user progress after authentication
                            await progressManager.loadProgress()
                        }
                } else {
                    AuthView(isAuthenticated: $supabaseManager.isAuthenticated)
                }
            }
            .task {
                await supabaseManager.checkExistingSession()
                // Ensure app blocking is in a clean state on launch
                // Blocks will be applied when user starts a focus session
                AppBlockingManager.shared.stopBlocking()
            }
            .onChange(of: supabaseManager.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated {
                    // Clear progress data on sign out
                    progressManager.clearData()
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
        case .background, .inactive:
            // App going to background - ensure blocks are maintained
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
