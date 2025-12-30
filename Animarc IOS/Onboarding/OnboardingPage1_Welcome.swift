//
//  OnboardingPage1_Welcome.swift
//  Animarc IOS
//
//  Page 1: Welcome & Value Proposition
//

import SwiftUI

struct OnboardingPage1_Welcome: View {
    @Binding var currentPage: Int
    let onSkipToAuth: () -> Void
    @State private var contentAppeared = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60) // Top spacer after safe area
                
                // Portal GIF
                GIFImageView(gifName: "Green portal")
                    .frame(width: 180, height: 180)
                    .shadow(color: Color(hex: "#7FFF00").opacity(0.5), radius: 20, x: 0, y: 0)
                    .opacity(contentAppeared ? 1 : 0)
                    .scaleEffect(contentAppeared ? 1 : 0.7)
                    .animation(.spring(response: 1.2, dampingFraction: 0.7), value: contentAppeared)
                
                Spacer()
                    .frame(height: 32)
                
                // Title
                Text("Welcome to Animarc")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: contentAppeared)
                
                Spacer()
                    .frame(height: 8)
                
                // Subtitle
                Text("Level up your focus")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: contentAppeared)
                
                Spacer()
                    .frame(height: 20)
                
                // Tagline
                Text("Turn focus sessions into an adventure")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .multilineTextAlignment(.center)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: contentAppeared)
                
                Spacer()
                    .frame(height: 80)
                
                // Get Started Button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Navigate to next page
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("Get Started")
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
                    .frame(height: 16)
                
                // Already have an account button
                Button(action: {
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Skip onboarding and go to auth
                    onSkipToAuth()
                }) {
                    Text("Already have an account")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: contentAppeared)
                
                Spacer()
                    .frame(height: 24)
                
                // Page indicator dots
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
        }
    }
}

#Preview {
    OnboardingPage1_Welcome(
        currentPage: .constant(0),
        onSkipToAuth: {}
    )
}

