//
//  RatingRequestPopup.swift
//  Animarc IOS
//
//  Popup view for requesting App Store rating
//

import SwiftUI

struct RatingRequestPopup: View {
    @Binding var isPresented: Bool
    let onYes: () -> Void
    let onNo: () -> Void
    
    // Animation state variables (matching other modals)
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    @State private var borderOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var starsScale: CGFloat = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background: Semi-transparent black overlay
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // Glassmorphic card container
                VStack(spacing: 24) {
                    // Title
                    Text("Enjoy Animarc?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(contentOpacity)
                    
                    // Message
                    Text("Could you support us with a 5-star rating? We'd be super grateful!")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .opacity(contentOpacity)
                    
                    // 5 golden stars
                    HStack(spacing: 8) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "#FFD700"))
                        }
                    }
                    .scaleEffect(starsScale)
                    .padding(.vertical, 8)
                    
                    // Buttons - stacked vertically
                    VStack(spacing: 12) {
                        // "5 Stars" button (light green)
                        Button(action: {
                            onYes()
                            dismiss()
                        }) {
                            Text("5 Stars")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(hex: "#22C55E"))
                                .cornerRadius(25)
                                .shadow(color: Color(hex: "#22C55E").opacity(0.6), radius: 15, x: 0, y: 5)
                        }
                        .opacity(contentOpacity)
                        
                        // "No" button (white)
                        Button(action: {
                            onNo()
                            dismiss()
                        }) {
                            Text("No")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#1A2332"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(25)
                        }
                        .opacity(contentOpacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding(.top, 50)
                .padding(.bottom, 30)
                .padding(.horizontal, 30)
                .scaleEffect(cardScale)
                .background(
                    // Glassmorphic background (matching other modals)
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
                        .opacity(borderOpacity)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 20)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Phase 1: Background fade-in (0.3s)
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0.5
        }
        
        // Phase 2: Card entrance (0.5s, starts at 0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardScale = 1.0
                borderOpacity = 1.0
            }
        }
        
        // Phase 3: Stars pop (0.4s, starts at 0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                starsScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    starsScale = 1.0
                }
            }
        }
        
        // Phase 4: Content fade-in (0.3s, starts at 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                contentOpacity = 1.0
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

