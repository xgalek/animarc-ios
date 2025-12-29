//
//  OnboardingPage2_CoreLoop.swift
//  Animarc IOS
//
//  Page 2: Core Loop Visual
//

import SwiftUI

struct OnboardingPage2_CoreLoop: View {
    @Binding var currentPage: Int
    @State private var contentAppeared = false
    
    // E-Rank info
    private let eRankInfo = RankService.getRankByCode("E") ?? RankService.allRanks[0]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Title at top
                HStack {
                    Text("Start Your Journey")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50) // Safe area top
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : -20)
                .animation(.easeOut(duration: 0.6), value: contentAppeared)
                
                Spacer()
                    .frame(height: 24)
                
                // Glassmorphic preview card
                VStack(spacing: 12) {
                    // Streak, XP Bar, Rank row
                    HStack(spacing: 8) {
                        // Streak flame + number
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 20))
                            Text("5")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        // XP Progress Bar
                        SimplifiedXPBarPreview()
                            .frame(height: 24)
                        
                        // Rank badge
                        Text("E-Rank")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .frame(height: 24)
                            .background(eRankInfo.swiftUIColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    
                    // FOCUS button preview
                    Button(action: {
                        // Non-functional preview button
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
                    .disabled(true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
                .background(
                    // Glassmorphic background
                    ZStack {
                        // Dark semi-transparent background
                        Color(hex: "#14141E")
                            .opacity(0.85)
                        
                        // Frosted glass effect
                        Color.white.opacity(0.02)
                    }
                )
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .overlay(
                    // Subtle border
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.white.opacity(0.05), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                .opacity(contentAppeared ? 1 : 0)
                .scaleEffect(contentAppeared ? 1 : 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: contentAppeared)
                
                Spacer()
                    .frame(height: 20)
                
                // Feature checklist
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#22C55E"))
                        Text("Start focus sessions")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#22C55E"))
                        Text("Block distracting apps automatically")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#22C55E"))
                        Text("Earn XP as you focus")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 30)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: contentAppeared)
                
                Spacer()
                    .frame(height: 60)
                
                // Next Button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Navigate to next page
                    withAnimation {
                        currentPage = 2
                    }
                }) {
                    Text("Next")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#4ADE80"))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 30)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: contentAppeared)
                
                Spacer()
                    .frame(height: 20)
                
                // Page indicator dots
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                .padding(.bottom, 34) // Safe area bottom
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "#1A2332"))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
        }
    }
}

#Preview {
    OnboardingPage2_CoreLoop(currentPage: .constant(1))
}

