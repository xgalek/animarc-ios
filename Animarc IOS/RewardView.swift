//
//  RewardView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct RewardView: View {
    let sessionDuration: Int
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Section - Close button
                HStack {
                    Spacer()
                    Button(action: {
                        navigationPath = NavigationPath()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                
                Spacer()
                
                // Center Content
                VStack(spacing: 24) {
                    // SESSION COMPLETE! text
                    Text("SESSION COMPLETE!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Session duration
                    Text("Focused for \(formattedDuration)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    
                    // XP reward display
                    Text("+50 XP")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "#22C55E"))
                        .shadow(color: Color(hex: "#22C55E").opacity(0.5), radius: 10, x: 0, y: 0)
                    
                    // Celebratory icon
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#FFD700"))
                        .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 10, x: 0, y: 0)
                }
                .padding(.vertical, 40)
                
                Spacer()
                
                // Stats Section
                VStack(spacing: 12) {
                    Text("Total XP: 2372")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    
                    Text("Current Level: 13")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .padding(.bottom, 40)
                
                // Bottom Section - CONTINUE button
                Button(action: {
                    navigationPath = NavigationPath()
                }) {
                    Text("CONTINUE")
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
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Helper Functions
    
    private var formattedDuration: String {
        let minutes = sessionDuration / 60
        let seconds = sessionDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RewardView(sessionDuration: 754, navigationPath: .constant(NavigationPath()))
    }
}

