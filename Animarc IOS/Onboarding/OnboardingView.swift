//
//  OnboardingView.swift
//  Animarc IOS
//
//  Main onboarding container with TabView for page navigation
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var savedUsername = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject var progressManager: UserProgressManager
    
    var body: some View {
        ZStack {
            // Dark background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                OnboardingPage1_Welcome(
                    currentPage: $currentPage,
                    onSkipToAuth: {
                        // Skip onboarding and mark as completed
                        hasCompletedOnboarding = true
                    }
                )
                .tag(0)
                
                OnboardingPage2_CoreLoop(currentPage: $currentPage)
                    .tag(1)
                
                OnboardingPage3_Username(
                    currentPage: $currentPage,
                    savedUsername: $savedUsername
                )
                .tag(2)
                
                OnboardingPage4_Auth(
                    currentPage: $currentPage,
                    savedUsername: $savedUsername,
                    onComplete: {
                        // Mark onboarding as completed
                        // This will trigger @AppStorage in Animarc_IOSApp to update
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserProgressManager.shared)
}

