//
//  FocusSessionView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

enum PomodoroPhase {
    case focus, rest
}

struct FocusSessionView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var settings: FocusSessionSettings = FocusSessionSettings.load()
    @State private var elapsedTime: Int = 0 // For stopwatch mode (counts up)
    @State private var remainingTime: Int = 0 // For timer/pomodoro modes (counts down)
    @State private var totalElapsedTime: Int = 0 // Total time for XP calculation
    @State private var currentPhase: PomodoroPhase = .focus
    @State private var currentPomodoroNumber: Int = 1
    @State private var timer: Timer?
    @State private var blockingError: String?
    
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
                    VStack(spacing: 8) {
                        Text(formattedTime)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Phase indicator for Pomodoro
                        if settings.mode == .pomodoro {
                            HStack(spacing: 8) {
                                Text(currentPhase == .focus ? "Focus" : "Break")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(currentPhase == .focus ? Color(hex: "#22C55E") : Color(hex: "#6B46C1"))
                                
                                Text("-")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                
                                Text("Pomodoro \(currentPomodoroNumber)/\(settings.pomodoroCount)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
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
                    // Pass total elapsed time in seconds to RewardView
                    let timeForReward = settings.mode == .stopwatch ? elapsedTime : totalElapsedTime
                    navigationPath.append("Reward-\(timeForReward)")
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
            // Load settings
            settings = FocusSessionSettings.load()
            initializeTimer()
            startTimer()
            startAppBlocking()
        }
        .onDisappear {
            stopTimer()
            stopAppBlocking()
        }
        .alert("Blocking Error", isPresented: .constant(blockingError != nil)) {
            Button("OK") {
                blockingError = nil
            }
        } message: {
            if let error = blockingError {
                Text(error)
            }
        }
    }
    
    // MARK: - Timer Functions
    
    private func initializeTimer() {
        switch settings.mode {
        case .stopwatch:
            elapsedTime = 0
            totalElapsedTime = 0
        case .timer:
            remainingTime = settings.timerDuration * 60
            totalElapsedTime = 0
        case .pomodoro:
            remainingTime = 25 * 60 // 25 minutes for first focus phase
            totalElapsedTime = 0
            currentPhase = .focus
            currentPomodoroNumber = 1
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            handleTimerTick()
        }
    }
    
    private func handleTimerTick() {
        switch settings.mode {
        case .stopwatch:
            elapsedTime += 1
            totalElapsedTime = elapsedTime
        case .timer:
            if remainingTime > 0 {
                remainingTime -= 1
                totalElapsedTime += 1
            } else {
                // Timer complete - go to rewards
                stopTimer()
                navigationPath.append("Reward-\(totalElapsedTime)")
            }
        case .pomodoro:
            handlePomodoroTimer()
        }
    }
    
    private func handlePomodoroTimer() {
        if remainingTime > 0 {
            remainingTime -= 1
            totalElapsedTime += 1
        } else {
            // Phase complete
            if currentPhase == .focus {
                // Check if this was the last pomodoro
                if currentPomodoroNumber == settings.pomodoroCount {
                    // End session - go to rewards (skip last break)
                    stopTimer()
                    navigationPath.append("Reward-\(totalElapsedTime)")
                } else {
                    // Start break phase
                    currentPhase = .rest
                    remainingTime = 5 * 60 // 5 minutes
                }
            } else {
                // Break complete, start next focus
                currentPomodoroNumber += 1
                currentPhase = .focus
                remainingTime = 25 * 60 // 25 minutes
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var formattedTime: String {
        let time: Int
        switch settings.mode {
        case .stopwatch:
            time = elapsedTime
        case .timer, .pomodoro:
            time = remainingTime
        }
        
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - App Blocking Functions
    
    private func startAppBlocking() {
        // Refresh authorization status
        appBlockingManager.refreshAuthorizationStatus()
        
        // Only start blocking if authorized
        guard appBlockingManager.isAuthorized else {
            blockingError = "App blocking permission is required. Please grant permission in Settings."
            return
        }
        
        // Check if apps have been selected for blocking
        // If no apps selected yet, warn but don't block session (allow user to proceed)
        // They can configure blocking in settings for next time
        if appBlockingManager.blockedApplications.isEmpty {
            print("FocusSessionView: Warning - No apps selected for blocking. Session will continue without blocking.")
            // Don't show error - just log it. User can configure in settings.
            return
        }
        
        do {
            try appBlockingManager.startBlocking()
            print("FocusSessionView: App blocking started")
        } catch {
            blockingError = error.localizedDescription
            print("FocusSessionView: Failed to start blocking: \(error)")
        }
    }
    
    private func stopAppBlocking() {
        appBlockingManager.stopBlocking()
        print("FocusSessionView: App blocking stopped")
    }
}

#Preview {
    NavigationStack {
        FocusSessionView(navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}
