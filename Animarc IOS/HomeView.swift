//
//  HomeView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                // Top Status Bar
                HStack {
                    // Fire emoji and streak number
                    HStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 20))
                        Text("\(progressManager.currentStreak)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Stats text with different colors
                    HStack(spacing: 4) {
                        Text("\(progressManager.currentRank)-Rank")
                            .font(.headline)
                            .foregroundColor(progressManager.currentRankInfo.swiftUIColor)
                        Text("|")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Text("LVL \(progressManager.currentLevel)")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#A770FF"))
                        Text("|")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Text("\(progressManager.totalXP) xp")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#22C55E"))
                    }
                    
                    Spacer()
                    
                    // Avatar button
                    AvatarButton(showProfile: $showProfile)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Center Content
                VStack(spacing: 16) {
                    // Motivational quote
                    Text("Success is nothing more than a few simple disciplines, practiced every day.")
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    // Attribution
                    Text("-Jim Rohn")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
                .padding(.vertical, 20)
                
                // Portal Image
                GIFImageView(gifName: "Green portal")
                    .frame(width: 200, height: 200)
                    .shadow(color: Color(hex: "#7FFF00").opacity(0.5), radius: 20, x: 0, y: 0)
                    .padding(.top, 30)
                    .padding(.bottom, 40)
                
                // Focus Button
                Button(action: {
                    navigationPath.append("FocusSession")
                }) {
                    Text("FOCUS")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#6B46C1"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                        .shadow(color: Color(hex: "#4A90E2").opacity(0.4), radius: 25, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                Spacer()
                }
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "FocusSession" {
                    FocusSessionView(navigationPath: $navigationPath)
                        .environmentObject(progressManager)
                } else if destination.hasPrefix("Reward-") {
                    let durationStr = destination.replacingOccurrences(of: "Reward-", with: "")
                    let duration = Int(durationStr) ?? 0
                    RewardView(sessionDuration: duration, navigationPath: $navigationPath)
                        .environmentObject(progressManager)
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView(navigationPath: .constant(NavigationPath()))
                        .environmentObject(progressManager)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserProgressManager.shared)
}
