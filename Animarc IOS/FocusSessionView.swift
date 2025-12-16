//
//  FocusSessionView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import UIKit

enum PomodoroPhase {
    case focus, rest
}

struct FocusSessionView: View {
    @Binding var navigationPath: NavigationPath
    @EnvironmentObject var progressManager: UserProgressManager
    // TEMPORARILY DISABLED: App blocking code commented out pending Apple's approval
    // @StateObject private var appBlockingManager = AppBlockingManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var settings: FocusSessionSettings = FocusSessionSettings.load()
    @State private var elapsedTime: Int = 0 // For stopwatch mode (counts up)
    @State private var remainingTime: Int = 0 // For timer/pomodoro modes (counts down)
    @State private var totalElapsedTime: Int = 0 // Total time for XP calculation
    @State private var currentPhase: PomodoroPhase = .focus
    @State private var currentPomodoroNumber: Int = 1
    @State private var timer: Timer?
    // TEMPORARILY DISABLED: Blocking error state variables commented out
    // @State private var blockingError: String?
    // @State private var showBlockingError = false
    @State private var showEndConfirmation = false
    @AppStorage("KeepScreenOnDuringFocus") private var keepScreenOn: Bool = true
    
    // Portal entry animation - starts fully black, fades to reveal the world
    @State private var entryOverlayOpacity: Double = 1.0
    
    // Exit transition - fades parallax world to black before navigating to rewards
    @State private var showExitTransition = false
    @State private var pendingRewardDestination: String? = nil
    
    var body: some View {
        ZStack {
            // Parallax Background
            LottiePlayerView(name: "Parallax castle 1 json", loopMode: .loop, speed: 0.7)
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
                    .allowsHitTesting(true)
                    
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
                
                // Center Section - Character walking animation
                GIFImageView(gifName: "Character walking castle")
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.bottom, 120)
            }
            .allowsHitTesting(true)
            
            // Tap area to show confirmation popup
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    showEndConfirmation = true
                }
            
            // End Session Confirmation Popup
            if showEndConfirmation {
                ZStack {
                    // Semi-transparent background overlay
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showEndConfirmation = false
                        }
                    
                    // Confirmation card
                    VStack(spacing: 24) {
                        Text("This will end your focus session")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                        
                        HStack(spacing: 16) {
                            // Cancel button (left)
                            Button(action: {
                                showEndConfirmation = false
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#F3F4F6"))
                                    .cornerRadius(12)
                            }
                            
                            // End button (right)
                            Button(action: {
                                showEndConfirmation = false
                                stopTimer()
                                // Pass total elapsed time in seconds to RewardView
                                let timeForReward = settings.mode == .stopwatch ? elapsedTime : totalElapsedTime
                                navigateToRewards(duration: timeForReward)
                            }) {
                                Text("End")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(hex: "#DC2626"))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .frame(width: 280)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                }
            }
            
            // Portal entry overlay - fades out to reveal the parallax world
            // This creates the "emerging from portal" effect
            Color.black
                .opacity(entryOverlayOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Exit transition overlay - fades parallax world to black before navigating to rewards
            if showExitTransition {
                ExitTransitionOverlay {
                    // Transition complete - navigate to reward screen
                    showExitTransition = false
                    
                    // Disable the default navigation animation for seamless black-to-black transition
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        if let destination = pendingRewardDestination {
                            navigationPath.append(destination)
                            pendingRewardDestination = nil
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // Load settings
            settings = FocusSessionSettings.load()
            initializeTimer()
            startTimer()
            // TEMPORARILY DISABLED: App blocking code commented out pending Apple's approval
            // startAppBlocking()
            
            // Portal fade-reveal animation - emerge into the parallax world
            // Haptic feedback when emerging
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            
            // Fade from black to reveal the world (1.5 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 1.5)) {
                    entryOverlayOpacity = 0.0
                }
            }
        }
        .onDisappear {
            stopTimer()
            // TEMPORARILY DISABLED: App blocking code commented out pending Apple's approval
            // stopAppBlocking()
        }
        // TEMPORARILY DISABLED: Blocking error alert commented out pending Apple's approval
        /*
        .alert("Blocking Error", isPresented: $showBlockingError) {
            Button("OK") {
                blockingError = nil
                showBlockingError = false
            }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
                blockingError = nil
                showBlockingError = false
            }
        } message: {
            if let error = blockingError {
                Text(error)
            }
        }
        */
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
        // Disable idle timer if setting is enabled (default ON)
        if keepScreenOn {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
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
                // Timer complete - go to rewards with transition
                stopTimer()
                navigateToRewards(duration: totalElapsedTime)
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
                    // End session - go to rewards with transition (skip last break)
                    stopTimer()
                    navigateToRewards(duration: totalElapsedTime)
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
        
        // ALWAYS re-enable idle timer when session ends
        UIApplication.shared.isIdleTimerDisabled = false
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
    
    // MARK: - Navigation Helper
    
    private func navigateToRewards(duration: Int) {
        // Store the destination
        pendingRewardDestination = "Reward-\(duration)"
        
        // Trigger exit transition
        showExitTransition = true
    }
    
    // MARK: - App Blocking Functions
    // TEMPORARILY DISABLED: Commented out pending Apple's approval of Family Controls entitlement
    
    /*
    private func startAppBlocking() {
        // Refresh authorization status
        appBlockingManager.refreshAuthorizationStatus()
        
        // Only start blocking if authorized
        guard appBlockingManager.isAuthorized else {
            blockingError = "App blocking permission is required. Please grant Screen Time permission in Settings to block distracting apps during focus sessions."
            showBlockingError = true
            // Don't block session - allow user to proceed without blocking
            print("FocusSessionView: App blocking not authorized - session will continue without blocking")
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
            // Graceful degradation - don't block session if blocking fails
            blockingError = "Failed to start app blocking: \(error.localizedDescription). Your focus session will continue without app blocking."
            showBlockingError = true
            print("FocusSessionView: Failed to start blocking: \(error)")
        }
    }
    
    private func stopAppBlocking() {
        appBlockingManager.stopBlocking()
        print("FocusSessionView: App blocking stopped")
    }
    */
}

#Preview {
    NavigationStack {
        FocusSessionView(navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}
