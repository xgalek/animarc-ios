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
            }
            .onChange(of: supabaseManager.isAuthenticated) { _, isAuthenticated in
                if !isAuthenticated {
                    // Clear progress data on sign out
                    progressManager.clearData()
                }
            }
        }
    }
}
