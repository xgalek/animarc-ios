//
//  OnboardingPage3_Username.swift
//  Animarc IOS
//
//  Page 3: Username Input
//

import SwiftUI

struct OnboardingPage3_Username: View {
    @Binding var currentPage: Int
    @Binding var savedUsername: String
    
    @State private var username = ""
    @State private var contentAppeared = false
    
    // E-Rank info
    private let eRankInfo = RankService.getRankByCode("E") ?? RankService.allRanks[0]
    
    // Validation: 2-20 chars, alphanumeric + underscore/hyphen
    private var isValidUsername: Bool {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 && trimmed.count <= 20 else { return false }
        
        // Allow alphanumeric, underscore, and hyphen
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return trimmed.rangeOfCharacter(from: allowedCharacters.inverted) == nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60) // Top spacer after safe area
                
                // Title
                Text("What should we call you")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.6), value: contentAppeared)
                
                Spacer()
                    .frame(height: 12)
                
                // Subtitle
                Text("This will be your identity in battles")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .multilineTextAlignment(.center)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.1), value: contentAppeared)
                
                Spacer()
                    .frame(height: 32)
                
                // Text input field (glassmorphic)
                TextField("Enter your name", text: $username)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
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
                    .cornerRadius(16)
                    .overlay(
                        // Border that changes color based on validation
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                username.isEmpty ? Color.white.opacity(0.1) : 
                                isValidUsername ? Color(hex: "#22C55E").opacity(0.3) : Color(hex: "#DC2626").opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .padding(.horizontal, 30)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: contentAppeared)
                    .onSubmit {
                        if isValidUsername {
                            proceedToNextPage()
                        }
                    }
                
                Spacer()
                    .frame(height: 16)
                
                // Starting rank preview
                HStack(spacing: 8) {
                    Text("E-Rank")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(eRankInfo.swiftUIColor)
                        .cornerRadius(6)
                    
                    Text("Starting as E-Rank Hunter")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 20)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: contentAppeared)
                
                Spacer()
                    .frame(height: 80)
                
                // Continue Button
                Button(action: {
                    proceedToNextPage()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isValidUsername ? Color(hex: "#4ADE80") : Color(hex: "#9CA3AF"))
                        .cornerRadius(8)
                }
                .disabled(!isValidUsername)
                .opacity(isValidUsername ? 1.0 : 0.6)
                .padding(.horizontal, 30)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: contentAppeared)
                
                Spacer()
                    .frame(height: 20)
                
                // Page indicator dots
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white)
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
    
    private func proceedToNextPage() {
        guard isValidUsername else { return }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Store username temporarily
        savedUsername = trimmedUsername
        
        // Navigate to Page 4 (AuthView)
        withAnimation {
            currentPage = 3
        }
    }
}

#Preview {
    OnboardingPage3_Username(
        currentPage: .constant(2),
        savedUsername: .constant("")
    )
}

