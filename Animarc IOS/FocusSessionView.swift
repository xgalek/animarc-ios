//
//  FocusSessionView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

struct FocusSessionView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var progressManager: UserProgressManager
    @Environment(\.dismiss) var dismiss
    @State private var elapsedTime: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Section
                HStack {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Timer display
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Spacer to balance the back button
                    Color.clear
                        .frame(width: 44, height: 44)
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                }
                
                Spacer()
                
                // Center Section - Character placeholder
                // TODO: Replace with animated walking character sprite
                Circle()
                    .fill(Color(hex: "#7FFF00"))
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "#7FFF00").opacity(0.5), radius: 15, x: 0, y: 0)
                
                Spacer()
                
                // Bottom Section
                Button(action: {
                    stopTimer()
                    // Pass elapsed time in seconds to RewardView
                    navigationPath.append("Reward-\(elapsedTime)")
                }) {
                    Text("END SESSION")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#DC2626"))
                        .cornerRadius(25)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var formattedTime: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        FocusSessionView(navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}
