//
//  HomeView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI
import FamilyControls

struct HomeView: View {
    @EnvironmentObject var progressManager: UserProgressManager
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @StateObject private var errorManager = ErrorManager.shared
    @State private var navigationPath = NavigationPath()
    @State private var showProfile = false
    @State private var showLevelUpModal = false
    @State private var showItemDropModal = false
    @State private var showStreakCelebration = false
    @State private var showPermissionModal = false
    @State private var showPermissionDeniedAlert = false
    @State private var isRequestingPermission = false
    @State private var showFocusConfig = false
    @State private var isRefreshing = false
    
    private let streakCelebrationKey = "lastStreakCelebrationShownDate"
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background
                Color(hex: "#1A2332")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Persistent error banner if errorMessage is set
                        if let errorMsg = progressManager.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                Text(errorMsg)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    Task {
                                        isRefreshing = true
                                        await progressManager.loadProgress()
                                        isRefreshing = false
                                    }
                                }) {
                                    Text("Retry")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#DC2626"))
                            .padding(.top, 8)
                        }
                        
                        // Top Status Bar
                        HStack {
                    // Fire emoji and streak number (tappable to show celebration)
                    Button(action: {
                        showStreakCelebrationManually()
                    }) {
                        HStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 20))
                            Text("\(progressManager.currentStreak)")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    // Stats text with different colors
                    HStack(spacing: 4) {
                        Text("\(progressManager.currentRank)-Rank")
                            .font(.headline)
                            .foregroundColor(progressManager.currentRankInfo.swiftUIColor)
                        Text("|")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Text("LVL \(progressManager.currentLevel)")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#A770FF"))
                        Text("|")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                        Text("\(progressManager.totalXP) xp")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#22C55E"))
                    }
                    
                    Spacer()
                    
                    // Avatar button
                    AvatarButton(showProfile: $showProfile)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Center Content
                VStack(spacing: 16) {
                    // Motivational quote
                    Text("Success is nothing more than a few simple disciplines, practiced every day.")
                        .font(.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    // Attribution
                    Text("-Jim Rohn")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
                .padding(.vertical, 20)
                
                // Portal Image
                GIFImageView(gifName: "Green portal")
                    .frame(width: 200, height: 200)
                    .shadow(color: Color(hex: "#7FFF00").opacity(0.5), radius: 20, x: 0, y: 0)
                    .padding(.top, 30)
                    .padding(.bottom, 40)
                
                // Focus Button
                Button(action: {
                    handleFocusButtonTap()
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
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                .disabled(isRequestingPermission)
                
                Spacer()
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .toast(errorManager: errorManager)
            .navigationDestination(for: String.self) { destination in
                if destination == "FocusSession" {
                    FocusSessionView(navigationPath: $navigationPath)
                        .environmentObject(progressManager)
                } else if destination.hasPrefix("Reward-") {
                    let durationStr = destination.replacingOccurrences(of: "Reward-", with: "")
                    let duration = Int(durationStr) ?? 0
                    RewardView(sessionDuration: duration, navigationPath: $navigationPath)
                        .environmentObject(progressManager)
                }
            }
            .sheet(isPresented: $showProfile) {
                NavigationStack {
                    ProfileView(navigationPath: .constant(NavigationPath()))
                        .environmentObject(progressManager)
                }
            }
            .onAppear {
                // Check for pending rewards when view appears (including when returning from RewardView)
                checkAndShowPendingRewards()
                // Check for streak celebration (after rewards)
                checkAndShowStreakCelebration()
                // Refresh authorization status
                appBlockingManager.refreshAuthorizationStatus()
            }
            .sheet(isPresented: $showPermissionModal) {
                AppBlockingPermissionModal(
                    isRequestingPermission: $isRequestingPermission,
                    onPermissionGranted: {
                        showPermissionModal = false
                        showFocusConfig = true
                    },
                    onPermissionDenied: {
                        showPermissionModal = false
                        showPermissionDeniedAlert = true
                    }
                )
            }
            .alert("Permission Required", isPresented: $showPermissionDeniedAlert) {
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Focus sessions require app blocking permission. Please grant Screen Time permission in Settings to continue.")
            }
            .sheet(isPresented: $showLevelUpModal) {
                LevelUpModalView(
                    oldLevel: progressManager.pendingLevelUp?.oldLevel ?? 1,
                    newLevel: progressManager.pendingLevelUp?.newLevel ?? 1,
                    rankUp: progressManager.pendingRankUp
                ) {
                    // On dismiss, clear level up and check for item drop
                    progressManager.pendingLevelUp = nil
                    progressManager.pendingRankUp = nil
                    showLevelUpModal = false
                    
                    // Check for item drop after level up modal closes
                    if progressManager.pendingItemDrop != nil {
                        showItemDropModal = true
                    }
                }
            }
            .sheet(isPresented: $showItemDropModal) {
                if let item = progressManager.pendingItemDrop {
                    ItemDropModalView(item: item) {
                        // On dismiss, clear item drop
                        progressManager.pendingItemDrop = nil
                        showItemDropModal = false
                    }
                }
            }
            .sheet(isPresented: $showStreakCelebration) {
                StreakCelebrationModalView(
                    streakCount: progressManager.currentStreak
                ) {
                    showStreakCelebration = false
                }
            }
            .sheet(isPresented: $showFocusConfig) {
                FocusConfigurationModal(
                    navigationPath: $navigationPath
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleFocusButtonTap() {
        // Check if permission has been requested
        if !appBlockingManager.hasRequestedPermission {
            // First time - show permission modal
            showPermissionModal = true
            return
        }
        
        // Check current authorization status
        appBlockingManager.refreshAuthorizationStatus()
        
        if appBlockingManager.isAuthorized {
            // Permission granted - show configuration modal first
            showFocusConfig = true
        } else {
            // Permission denied or revoked - show alert
            showPermissionDeniedAlert = true
        }
    }
    
    private func checkAndShowPendingRewards() {
        // First check for level up
        if progressManager.pendingLevelUp != nil {
            showLevelUpModal = true
            return
        }
        
        // If no level up, check for item drop
        if progressManager.pendingItemDrop != nil {
            showItemDropModal = true
        }
    }
    
    private func shouldShowStreakCelebration() -> Bool {
        // Don't show if data is still loading
        if progressManager.isLoading {
            return false
        }
        
        // Don't show if streak is 0
        if progressManager.currentStreak <= 0 {
            return false
        }
        
        // Check if already shown today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Use date formatter for day-level comparison
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        
        let todayString = dateFormatter.string(from: today)
        
        if let lastShownDateString = UserDefaults.standard.string(forKey: streakCelebrationKey),
           lastShownDateString == todayString {
            return false // Already shown today
        }
        
        return true
    }
    
    private func checkAndShowStreakCelebration() {
        // Only show if no other modals are showing and conditions are met
        guard !showLevelUpModal, !showItemDropModal else {
            return // Wait for other modals to finish
        }
        
        guard shouldShowStreakCelebration() else {
            return
        }
        
        // Mark as shown today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone.current
        let todayString = dateFormatter.string(from: Date())
        UserDefaults.standard.set(todayString, forKey: streakCelebrationKey)
        
        // Show the modal
        showStreakCelebration = true
    }
    
    private func showStreakCelebrationManually() {
        // Manual trigger - bypass once-per-day check
        // Only check if data is loaded and streak > 0
        guard !progressManager.isLoading, progressManager.currentStreak > 0 else {
            return
        }
        
        // Only show if no other modals are showing
        guard !showLevelUpModal, !showItemDropModal else {
            return
        }
        
        // Show the modal (don't update UserDefaults for manual triggers)
        showStreakCelebration = true
    }
    
    private func refreshData() async {
        isRefreshing = true
        await progressManager.loadProgress()
        isRefreshing = false
    }
}

// MARK: - Level Up Modal

struct LevelUpModalView: View {
    let oldLevel: Int
    let newLevel: Int
    let rankUp: (oldRank: RankInfo, newRank: RankInfo)?
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#6B46C1").opacity(0.95),
                    Color(hex: "#FFD700").opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("LEVEL UP! 🎉")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Level display
                VStack(spacing: 8) {
                    Text("Level \(oldLevel)")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("Level \(newLevel)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "#FFD700"))
                }
                
                // Rank Up indicator (if applicable)
                if let rankUp = rankUp {
                    VStack(spacing: 8) {
                        Text("⭐ RANK UP!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(rankUp.newRank.swiftUIColor)
                        
                        Text("\(rankUp.oldRank.code)-Rank → \(rankUp.newRank.code)-Rank")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(rankUp.newRank.title)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(rankUp.newRank.swiftUIColor.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#6B46C1"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
            .padding(.top, 60)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Item Drop Modal

struct ItemDropModalView: View {
    let item: PortalItem
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "#FFD700").opacity(0.95),
                    Color(hex: "#FFA500").opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("NEW ITEM! 🎁")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                
                // Rank badge
                Text("\(item.rolledRank)-RANK")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(item.rankColor)
                    .cornerRadius(10)
                
                // Item icon
                AsyncImage(url: URL(string: item.iconUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .shadow(color: item.rankColor.opacity(0.5), radius: 15, x: 0, y: 0)
                    case .failure:
                        Image(systemName: "gift.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.8))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Item name
                Text(item.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Stat bonus
                Text("+\(item.statValue) \(item.statType)")
                    .font(.headline)
                    .foregroundColor(item.rankColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(10)
                
                Spacer()
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Collect")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FFA500"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#FFA500").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
            .padding(.top, 90)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Streak Celebration Modal

struct StreakCelebrationModalView: View {
    let streakCount: Int
    let onDismiss: () -> Void
    
    @State private var flameScale: CGFloat = 1.0
    @State private var flameGlow: CGFloat = 0.5
    @State private var selectedMessage: String = ""
    
    private let motivationalMessages = [
        "Way to show up! Keep the habit strong",
        "One step closer. Every day counts.",
        "You got this! Maintain that perfect record.",
        "Future You is proud! Keep reaching for your goal.",
        "Streak secured! The momentum is yours.",
        "You're on fire! Don't let the flame die out."
    ]
    
    private var calendarDays: [(date: Date, dayAbbrev: String, isCompleted: Bool, isToday: Bool, isFuture: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find Monday of current week
        let weekday = calendar.component(.weekday, from: today)
        // Convert: Sunday=1, Monday=2, ..., Saturday=7
        // We want Monday=0, so: (weekday + 5) % 7
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        
        var days: [(date: Date, dayAbbrev: String, isCompleted: Bool, isToday: Bool, isFuture: Bool)] = []
        
        // Day abbreviations for Mon-Sun
        let dayAbbrevs = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        
        // Generate 7 days starting from Monday
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                let dateStart = calendar.startOfDay(for: date)
                let isToday = calendar.isDateInToday(date)
                let isFuture = dateStart > today
                
                // Calculate if this day is within the streak
                // Streak includes today and the previous (streakCount - 1) days
                // daysAgo: positive = days in the past, 0 = today, negative = future
                let daysAgo = calendar.dateComponents([.day], from: dateStart, to: today).day ?? 0
                // Completed if: not future AND within streak range (0 to streakCount-1)
                let isCompleted = daysAgo >= 0 && daysAgo < streakCount
                
                days.append((
                    date: date,
                    dayAbbrev: dayAbbrevs[i],
                    isCompleted: isCompleted,
                    isToday: isToday,
                    isFuture: isFuture
                ))
            }
        }
        
        return days
    }
    
    var body: some View {
        ZStack {
            // Background - dark theme
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                // Large animated flame icon with streak number
                VStack(spacing: 16) {
                    Text("🔥")
                        .font(.system(size: 80))
                        .scaleEffect(flameScale)
                        .shadow(color: Color(hex: "#FF6B35").opacity(flameGlow), radius: 20, x: 0, y: 0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                flameScale = 1.15
                            }
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                flameGlow = 1.0
                            }
                        }
                    
                    // Streak number
                    Text("\(streakCount)")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.white)
                    
                    // "days streak!" text
                    Text("days streak!")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: "#FF6B35"))
                }
                
                // 7-day calendar
                VStack(spacing: 12) {
                    Text("Last 7 Days")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                    
                    HStack(spacing: 10) {
                        ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, day in
                            VStack(spacing: 6) {
                                // Day circle
                                ZStack {
                                    Circle()
                                        .fill(day.isCompleted || day.isToday ? Color(hex: "#FF6B35") : Color(hex: "#374151"))
                                        .frame(width: 40, height: 40)
                                    
                                    if day.isToday {
                                        Text("🔥")
                                            .font(.system(size: 18))
                                    } else if day.isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Day label
                                Text(day.dayAbbrev)
                                    .font(.caption)
                                    .foregroundColor(day.isCompleted || day.isToday ? Color(hex: "#FF6B35") : Color(hex: "#9CA3AF"))
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                
                // Motivational text
                Text(selectedMessage)
                    .font(.title3)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .onAppear {
                        // Set message once when modal appears
                        if selectedMessage.isEmpty {
                            selectedMessage = motivationalMessages.randomElement() ?? motivationalMessages[0]
                        }
                    }
                
                Spacer()
                
                // Continue button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#FF6B35"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#FF6B35").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 60)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Focus Session Settings Model

enum FocusMode: String, Codable {
    case stopwatch, timer, pomodoro
}

struct FocusSessionSettings: Codable {
    var mode: FocusMode
    var timerDuration: Int // minutes (10-120)
    var pomodoroCount: Int // number of pomodoros (1-10)
    
    static let userDefaultsKey = "FocusSessionSettings"
    
    static func load() -> FocusSessionSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(FocusSessionSettings.self, from: data) else {
            return FocusSessionSettings(mode: .stopwatch, timerDuration: 25, pomodoroCount: 1)
        }
        return settings
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
}

// MARK: - Focus Configuration Modal

struct FocusConfigurationModal: View {
    @Binding var navigationPath: NavigationPath
    @State private var selectedTag: String? = nil
    @State private var showFocusSettings = false
    @State private var focusSettings = FocusSessionSettings.load()
    @Environment(\.dismiss) var dismiss
    
    private let focusTags = ["Deep Work", "Study", "Reading", "Creative Work", "Side Project", "Personal Dev", "Other"]
    
    private var modeDisplayName: String {
        switch focusSettings.mode {
        case .stopwatch: return "Stopwatch"
        case .timer: return "Timer"
        case .pomodoro: return "Pomodoro"
        }
    }
    
    private var modeIcon: String {
        switch focusSettings.mode {
        case .stopwatch: return "stopwatch"
        case .timer: return "timer"
        case .pomodoro: return "circle.fill"
        }
    }
    
    private var durationDisplay: (symbol: String, text: String) {
        switch focusSettings.mode {
        case .stopwatch:
            return ("∞", "Unlimited")
        case .timer:
            return ("\(focusSettings.timerDuration)m", "\(focusSettings.timerDuration) min")
        case .pomodoro:
            let count = focusSettings.pomodoroCount
            return ("\(count)", "\(count) Pomodoro\(count > 1 ? "s" : "")")
        }
    }
    
    var body: some View {
        ZStack {
            // Background - dark theme
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                Text("What would you like to focus on?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 80)
                
                // Horizontal scrolling pill buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(focusTags, id: \.self) { tag in
                            Button(action: {
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Toggle selection
                                if selectedTag == tag {
                                    selectedTag = nil
                                } else {
                                    selectedTag = tag
                                }
                            }) {
                                Text(tag)
                                    .font(.headline)
                                    .foregroundColor(selectedTag == tag ? .white : Color(hex: "#9CA3AF"))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(selectedTag == tag ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 8)
                
                // Mode and Duration boxes
                HStack(spacing: 16) {
                    // Left box - Mode
                    Button(action: {
                        showFocusSettings = true
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: modeIcon)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text(modeDisplayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("MODE")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(hex: "#374151"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Right box - Duration
                    Button(action: {
                        showFocusSettings = true
                    }) {
                        VStack(spacing: 8) {
                            Text(durationDisplay.symbol)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text(durationDisplay.text)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("DURATION")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color(hex: "#374151"))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Start session button
                Button(action: {
                    dismiss()
                    navigationPath.append("FocusSession")
                }) {
                    Text("Start session")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#22C55E"))
                        .cornerRadius(25)
                        .shadow(color: Color(hex: "#22C55E").opacity(0.6), radius: 15, x: 0, y: 0)
                }
                .padding(.horizontal, 30)
                
                // Edit settings text
                Button(action: {
                    // Placeholder - does nothing for now
                }) {
                    Text("Edit settings")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showFocusSettings) {
            FocusSettingsModal(settings: $focusSettings)
        }
        .onChange(of: showFocusSettings) { _, isShowing in
            if !isShowing {
                // Reload settings when modal closes
                focusSettings = FocusSessionSettings.load()
            }
        }
    }
}

// MARK: - Focus Settings Modal

struct FocusSettingsModal: View {
    @Binding var settings: FocusSessionSettings
    @StateObject private var appBlockingManager = AppBlockingManager.shared
    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var localSettings: FocusSessionSettings
    @Environment(\.dismiss) var dismiss
    
    init(settings: Binding<FocusSessionSettings>) {
        self._settings = settings
        self._localSettings = State(initialValue: settings.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // Background - dark theme
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Title
                    Text("Focus Settings")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 80)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        // Stopwatch tab
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            localSettings.mode = .stopwatch
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "stopwatch")
                                    .font(.system(size: 18))
                                Text("Stopwatch")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(localSettings.mode == .stopwatch ? .white : Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(localSettings.mode == .stopwatch ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 12,
                                    bottomLeadingRadius: 12,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 0
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Timer tab
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            localSettings.mode = .timer
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "timer")
                                    .font(.system(size: 18))
                                Text("Timer")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(localSettings.mode == .timer ? .white : Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(localSettings.mode == .timer ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Pomodoro tab
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            localSettings.mode = .pomodoro
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 18))
                                Text("Pomodoro")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(localSettings.mode == .pomodoro ? .white : Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(localSettings.mode == .pomodoro ? Color(hex: "#FF9500") : Color(hex: "#374151"))
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 12,
                                    topTrailingRadius: 12
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color(hex: "#374151"))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    
                    // Tab content
                    VStack(alignment: .leading, spacing: 16) {
                        if localSettings.mode == .stopwatch {
                            Text("Time counts up until you stop.")
                                .font(.body)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.horizontal, 20)
                        } else if localSettings.mode == .timer {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Duration")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(localSettings.timerDuration))m")
                                        .font(.headline)
                                        .foregroundColor(Color(hex: "#22C55E"))
                                }
                                .padding(.horizontal, 20)
                                
                                Slider(value: Binding(
                                    get: { Double(localSettings.timerDuration) },
                                    set: { newValue in
                                        let rounded = Int(newValue)
                                        if rounded != localSettings.timerDuration {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                        }
                                        localSettings.timerDuration = rounded
                                    }
                                ), in: 10...120, step: 1)
                                .tint(Color(hex: "#FF9500"))
                                .padding(.horizontal, 20)
                                
                                HStack {
                                    Text("10m")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                    Spacer()
                                    Text("120m")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                                .padding(.horizontal, 20)
                            }
                        } else if localSettings.mode == .pomodoro {
                            VStack(spacing: 16) {
                                // Picker for 1-10 pomodoros
                                Picker("Pomodoros", selection: $localSettings.pomodoroCount) {
                                    ForEach(1...10, id: \.self) { count in
                                        Text("\(count) Pomodoro\(count > 1 ? "s" : "")")
                                            .tag(count)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 150)
                                
                                // Explanation
                                Text("Each Pomodoro = 25min focus + 5min break")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    
                    // Apps allowed section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Apps allowed")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                showPicker = true
                            }) {
                                Text("Edit")
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#374151"))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Display app icons
                        if !appBlockingManager.selectedActivity.applicationTokens.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Array(appBlockingManager.selectedActivity.applicationTokens), id: \.self) { token in
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 8)
                        } else {
                            Text("No apps selected")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Save button
                    Button(action: {
                        settings = localSettings
                        settings.save()
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#22C55E"))
                            .cornerRadius(25)
                            .shadow(color: Color(hex: "#22C55E").opacity(0.6), radius: 15, x: 0, y: 0)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: selection) { _, newSelection in
            let applicationTokens = newSelection.applicationTokens
            appBlockingManager.setBlockedApplications(applicationTokens, selection: newSelection)
            selection = newSelection
        }
        .onAppear {
            selection = appBlockingManager.selectedActivity
        }
    }
}

// MARK: - App Blocking Permission Modal

struct AppBlockingPermissionModal: View {
    @Binding var isRequestingPermission: Bool
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2332")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "#6B46C1"))
                    .padding(.top, 40)
                
                // Title
                Text("Enter Focus Mode!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("Block distracting apps automatically")
                            .font(.body)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .multilineTextAlignment(.center)
                        
                        Text("during focus sessions.")
                            .font(.body)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Maximum focus. No interruptions.")
                        .font(.body)
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        requestPermission()
                    }) {
                        Text("Block Apps")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#6B46C1"))
                            .cornerRadius(25)
                            .shadow(color: Color(hex: "#6B46C1").opacity(0.6), radius: 15, x: 0, y: 0)
                    }
                    .disabled(isRequestingPermission)
                    
                    Button(action: {
                        onPermissionDenied()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .disabled(isRequestingPermission)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            do {
                try await AppBlockingManager.shared.requestAuthorization()
                await MainActor.run {
                    isRequestingPermission = false
                    if AppBlockingManager.shared.isAuthorized {
                        onPermissionGranted()
                    } else {
                        onPermissionDenied()
                    }
                }
            } catch {
                await MainActor.run {
                    isRequestingPermission = false
                    onPermissionDenied()
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserProgressManager.shared)
}
