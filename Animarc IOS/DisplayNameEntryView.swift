//
//  DisplayNameEntryView.swift
//  Animarc IOS
//
//  First-time user name entry popup modal
//

import SwiftUI

struct DisplayNameEntryView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @State private var nameText = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var contentAppeared = false
    
    let onDismiss: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        ZStack {
            // Warm amber/orange gradient background
            ZStack {
                // Base dark color
                Color.black
                    .ignoresSafeArea()
                
                // Warm amber radial gradient from top
                RadialGradient(
                    colors: [
                        Color(hex: "#B45309").opacity(0.6),
                        Color(hex: "#92400E").opacity(0.4),
                        Color(hex: "#78350F").opacity(0.2),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 0.7
                )
                .ignoresSafeArea()
                
                // Secondary gradient for depth
                RadialGradient(
                    colors: [
                        Color(hex: "#F97316").opacity(0.15),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
            .opacity(contentAppeared ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: contentAppeared)
            
            // Modal card - centered
            VStack(spacing: 24) {
                // Icon container with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FACC15"), Color(hex: "#F97316")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: Color(hex: "#F97316").opacity(0.5), radius: 15, x: 0, y: 5)
                    
                    Image(systemName: "pencil")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                .rotationEffect(.degrees(3))
                .offset(y: contentAppeared ? 0 : -20)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: contentAppeared)
                
                // Title
                Text("How should we call you?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .offset(y: contentAppeared ? 0 : -10)
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: contentAppeared)
                
                // Description - ensure full text displays
                Text("Choose a heroic name to begin your\njourney and challenge opponents.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: contentAppeared ? 0 : -10)
                    .opacity(contentAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: contentAppeared)
                
                // Text field with icon
                HStack(spacing: 12) {
                    Image(systemName: "person.text.rectangle")
                        .font(.system(size: 18))
                        .foregroundColor(nameText.isEmpty ? Color.white.opacity(0.4) : Color(hex: "#FACC15"))
                        .frame(width: 24)
                    
                    TextField("Enter your name...", text: $nameText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit {
                            if !nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                saveName()
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    nameText.isEmpty ? Color.white.opacity(0.1) : Color(hex: "#FACC15").opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
                .offset(y: contentAppeared ? 0 : 10)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: contentAppeared)
                
                // Primary button - Start Adventure
                Button(action: {
                    saveName()
                }) {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.black)
                                .scaleEffect(0.8)
                        } else {
                            Text("Start Adventure")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(.black)
                            
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FACC15"), Color(hex: "#F97316")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "#F97316").opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .disabled(isSaving || nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(nameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                .buttonStyle(PlainButtonStyle())
                .offset(y: contentAppeared ? 0 : 10)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: contentAppeared)
                
                // Secondary button - I'll decide later
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onDismiss()
                }) {
                    Text("I'll decide later")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
                .offset(y: contentAppeared ? 0 : 10)
                .opacity(contentAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: contentAppeared)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#1A2332"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.6), radius: 40, x: 0, y: 20)
            .padding(.horizontal, 24)
            .scaleEffect(contentAppeared ? 1 : 0.9)
            .opacity(contentAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: contentAppeared)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveName() {
        let trimmedName = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            return
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isSaving = true
        
        Task {
            guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Not authenticated. Please sign in again."
                    showError = true
                }
                return
            }
            
            do {
                let updatedProgress = try await SupabaseManager.shared.updateDisplayName(
                    userId: userId,
                    newName: trimmedName
                )
                
                await MainActor.run {
                    progressManager.userProgress = updatedProgress
                    isSaving = false
                    
                    // Mark name entry modal as seen so it never shows again
                    UserDefaults.standard.set(true, forKey: "hasSeenNameEntryModal")
                    UserDefaults.standard.synchronize()
                    
                    // Success haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Small delay for visual feedback, then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onSave()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save name: \(error.localizedDescription). Please try again."
                    showError = true
                }
                print("DisplayNameEntryView: Save error: \(error)")
            }
        }
    }
}

#Preview {
    DisplayNameEntryView(
        onDismiss: {},
        onSave: {}
    )
    .environmentObject(UserProgressManager.shared)
}

