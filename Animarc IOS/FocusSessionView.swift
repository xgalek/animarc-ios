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
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @StateObject private var musicManager = FocusMusicManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var settings: FocusSessionSettings = FocusSessionSettings.load()
    @State private var elapsedTime: Int = 0 // For stopwatch mode (counts up)
    @State private var remainingTime: Int = 0 // For timer/pomodoro modes (counts down)
    @State private var totalElapsedTime: Int = 0 // Total time for XP calculation
    @State private var currentPhase: PomodoroPhase = .focus
    @State private var currentPomodoroNumber: Int = 1
    @State private var timer: Timer?
    @State private var blockingError: String?
    @State private var showBlockingError = false
    @State private var showEndConfirmation = false
    @State private var showMusicSheet = false
    @AppStorage("KeepScreenOnDuringFocus") private var keepScreenOn: Bool = true
    
    // Portal entry animation - starts fully black, fades to reveal the world
    @State private var entryOverlayOpacity: Double = 1.0
    
    // Exit transition - fades parallax world to black before navigating to rewards
    @State private var showExitTransition = false
    @State private var pendingRewardDestination: String? = nil
    
    var body: some View {
        ZStack {
            // Parallax Background
            LottiePlayerView(name: "Parallax castle 1 json", loopMode: .loop, speed: 0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Section
                HStack {
                    // Spacer to balance the music button
                    Color.clear
                        .frame(width: 44, height: 44)
                        .padding(.leading, 20)
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Timer display
                    VStack(spacing: 8) {
                        Text(formattedTime)
                            .font(.custom("Poppins-ExtraBold", size: 80))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
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
                    .padding(.top, 90)
                    
                    Spacer()
                    
                    // Spacer to balance the music button
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
            
            // Music note button - Top layer with circular background
            VStack {
                HStack {
                    Button(action: {
                        showMusicSheet = true
                    }) {
                        ZStack {
                            // Circular background with blur effect
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            // Music note icon
                            Image(systemName: "music.note")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .allowsHitTesting(true)
            .zIndex(10) // Ensure it's on top layer
            
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
            startAppBlocking()
            
            // Home music is already paused when user clicked "Start session" button
            // Start focus music if enabled (home music was paused earlier in FocusConfigurationModal)
            if musicManager.focusMusicEnabled {
                musicManager.startFocusMusic()
            }
            
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
            stopAppBlocking()
            
            // Stop focus music when session ends
            musicManager.stopFocusMusic()
        }
        .sheet(isPresented: $showMusicSheet) {
            FocusMusicControlSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
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
    
    private func startAppBlocking() {
        print("📱 FocusSessionView.startAppBlocking() called")
        
        // Refresh authorization status
        appBlockingManager.refreshAuthorizationStatus()
        
        // Only start blocking if authorized
        guard appBlockingManager.isAuthorized else {
            blockingError = "App blocking permission is required. Please grant Screen Time permission in Settings to block distracting apps during focus sessions."
            showBlockingError = true
            // Don't block session - allow user to proceed without blocking
            print("❌ FocusSessionView: App blocking not authorized - session will continue without blocking")
            return
        }
        
        print("✅ FocusSessionView: Authorization confirmed, calling startBlocking()...")
        
        do {
            try appBlockingManager.startBlocking()
            print("✅ FocusSessionView: App blocking started successfully")
            print("   ℹ️ Now minimize the app and try to open TikTok, Instagram, etc.")
        } catch {
            // Graceful degradation - don't block session if blocking fails
            blockingError = "Failed to start app blocking: \(error.localizedDescription). Your focus session will continue without app blocking."
            showBlockingError = true
            print("❌ FocusSessionView: Failed to start blocking: \(error)")
        }
    }
    
    private func stopAppBlocking() {
        print("📱 FocusSessionView.stopAppBlocking() called")
        appBlockingManager.stopBlocking()
        print("✅ FocusSessionView: App blocking stopped")
    }
}

#Preview {
    NavigationStack {
        FocusSessionView(navigationPath: .constant(NavigationPath()))
            .environmentObject(UserProgressManager.shared)
    }
}

// MARK: - Focus Music Control Sheet

struct FocusMusicControlSheet: View {
    @StateObject private var musicManager = FocusMusicManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var orbRotation: Double = 0
    @State private var pulseRing1: Bool = false
    @State private var pulseRing2: Bool = false
    
    private var isPlaying: Bool { musicManager.focusMusicPlaying }
    private var isEnabled: Bool { musicManager.focusMusicEnabled }
    
    var body: some View {
        ZStack {
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("FOCUS MUSIC")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { musicManager.focusMusicEnabled },
                        set: { enabled in
                            musicManager.setFocusMusicEnabled(enabled)
                            if enabled {
                                musicManager.startFocusMusic()
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(Color(hex: "#FF9500"))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                Spacer()
                
                // Orb + Pulse Rings
                ZStack {
                    // Pulse ring 1
                    Circle()
                        .stroke(Color(hex: "#3B5068").opacity(pulseRing1 ? 0.0 : 0.25), lineWidth: 1.5)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseRing1 ? 1.6 : 1.0)
                        .animation(
                            isPlaying
                                ? .easeOut(duration: 2.4).repeatForever(autoreverses: false)
                                : .default,
                            value: pulseRing1
                        )
                    
                    // Pulse ring 2 (staggered)
                    Circle()
                        .stroke(Color(hex: "#3B5068").opacity(pulseRing2 ? 0.0 : 0.2), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseRing2 ? 1.5 : 1.0)
                        .animation(
                            isPlaying
                                ? .easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(1.0)
                                : .default,
                            value: pulseRing2
                        )
                    
                    // Dashed spinning border
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                        .foregroundColor(Color(hex: "#475569").opacity(0.4))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(orbRotation))
                    
                    // Orb
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#2A3A4E"),
                                        Color(hex: "#1E293B")
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 64
                                )
                            )
                            .frame(width: 128, height: 128)
                        
                        // Inner highlight
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.12), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .frame(width: 128, height: 128)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white.opacity(isEnabled ? 0.5 : 0.2))
                    }
                    .shadow(color: Color(hex: "#3B5068").opacity(0.4), radius: 30, x: 0, y: 0)
                }
                .opacity(isEnabled ? 1.0 : 0.4)
                .onAppear {
                    withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                        orbRotation = 360
                    }
                    if isPlaying {
                        pulseRing1 = true
                        pulseRing2 = true
                    }
                }
                .onChange(of: isPlaying) { playing in
                    if playing {
                        pulseRing1 = false
                        pulseRing2 = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            pulseRing1 = true
                            pulseRing2 = true
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.3)) {
                            pulseRing1 = false
                            pulseRing2 = false
                        }
                    }
                }
                
                // Track info
                VStack(spacing: 6) {
                    Text("CURRENTLY PLAYING")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(isEnabled ? .white.opacity(0.35) : .white.opacity(0.2))
                    
                    if let currentTrack = musicManager.focusMusicTrack {
                        Text(currentTrack.name.uppercased())
                            .font(.system(size: 22, weight: .bold))
                            .tracking(4)
                            .foregroundColor(isEnabled ? .white : .white.opacity(0.3))
                    } else {
                        Text("NO TRACK")
                            .font(.system(size: 22, weight: .bold))
                            .tracking(4)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.top, 32)
                
                Spacer()
                
                // Controls
                HStack(spacing: 48) {
                    Button {
                        musicManager.previousFocusMusicTrack()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isEnabled ? .white.opacity(0.55) : .white.opacity(0.2))
                    }
                    .disabled(!isEnabled)
                    
                    Button {
                        if musicManager.focusMusicPlaying {
                            musicManager.pauseFocusMusic()
                        } else if musicManager.focusMusicEnabled {
                            musicManager.resumeFocusMusic()
                        } else {
                            musicManager.startFocusMusic()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#FF9500"))
                                .frame(width: 72, height: 72)
                                .shadow(color: Color(hex: "#FF9500").opacity(0.35), radius: 16, x: 0, y: 4)
                            
                            Image(systemName: isPlaying ? "pause" : "play.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: "#1A2332"))
                        }
                    }
                    .disabled(!isEnabled)
                    .opacity(isEnabled ? 1.0 : 0.4)
                    
                    Button {
                        musicManager.nextFocusMusicTrack()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(isEnabled ? .white.opacity(0.55) : .white.opacity(0.2))
                    }
                    .disabled(!isEnabled)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
