//
//  PortalRaidResultView.swift
//  Animarc IOS
//
//  Portal raid result display - shows progress and rewards
//

import SwiftUI

struct PortalRaidResultView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progressManager: UserProgressManager
    
    let result: RaidAttemptResult
    let boss: PortalBoss
    let progress: PortalRaidProgress
    let rewards: (xp: Int, gold: Int)?
    let onAttackAgain: () -> Void
    let onReturnHome: () -> Void
    
    @State private var contentAppeared = false
    @State private var showRewards = false
    @State private var showItemDropModal = false
    
    private var isBossDefeated: Bool {
        result.bossDefeated
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#221a10")
                .ignoresSafeArea()
            
            // Glow gradient
            VStack {
                RadialGradient(
                    colors: isBossDefeated
                        ? [Color(hex: "#f49d25").opacity(0.4), Color.clear]
                        : [Color(hex: "#F97316").opacity(0.3), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
                .frame(height: UIScreen.main.bounds.height * 0.6)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            // Floating particles (only for defeat)
            if isBossDefeated {
                floatingParticles
            }
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Header
                headerSection
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : -30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: contentAppeared)
                
                Spacer()
                
                // Boss avatar with progress
                bossProgressSection
                    .opacity(contentAppeared ? 1 : 0)
                    .scaleEffect(contentAppeared ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: contentAppeared)
                
                Spacer()
                
                // Damage dealt info
                damageInfoSection
                    .padding(.top, 24)
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: showRewards)
                
                // Rewards card (only if defeated)
                if isBossDefeated, let rewards = rewards {
                    rewardsCard(rewards: rewards)
                        .padding(.top, 20)
                        .opacity(showRewards ? 1 : 0)
                        .offset(y: showRewards ? 0 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6), value: showRewards)
                }
                
                // Action buttons
                actionButtons
                    .padding(.top, 24)
                    .opacity(showRewards ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.8), value: showRewards)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showItemDropModal) {
            if let item = progressManager.pendingPortalBossItemDrop {
                PortalBossItemDropModalView(item: item) {
                    // On dismiss, clear item drop
                    progressManager.pendingPortalBossItemDrop = nil
                    showItemDropModal = false
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRewards = true
            }
            
            // Check for portal boss item drop when view appears
            if isBossDefeated && progressManager.pendingPortalBossItemDrop != nil {
                // Small delay to let rewards animation finish first
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showItemDropModal = true
                }
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(isBossDefeated ? .success : .warning)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(isBossDefeated ? "BOSS DEFEATED!" : "BOSS WEAKENED")
                .font(.system(size: 36, weight: .black))
                .tracking(-1)
                .foregroundStyle(
                    isBossDefeated
                        ? LinearGradient(
                            colors: [Color(hex: "#FDE047"), Color(hex: "#f49d25"), Color(hex: "#EA580C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color(hex: "#F97316"), Color(hex: "#EA580C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 4)
            
            // Glowing underline
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    isBossDefeated
                        ? Color(hex: "#f49d25").opacity(0.5)
                        : Color(hex: "#F97316").opacity(0.5)
                )
                .frame(width: 96, height: 4)
                .blur(radius: 2)
        }
    }
    
    // MARK: - Boss Progress Section
    
    private var bossProgressSection: some View {
        VStack(spacing: 20) {
            // Boss avatar
            ZStack {
                if let uiImage = UIImage(named: boss.imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Circle()
                        .fill(Color(hex: "#374151"))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 40))
                        )
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        isBossDefeated ? Color(hex: "#f49d25") : Color(hex: "#F97316"),
                        lineWidth: 3
                    )
            )
            .shadow(
                color: isBossDefeated ? Color(hex: "#f49d25").opacity(0.4) : Color(hex: "#F97316").opacity(0.3),
                radius: 15
            )
            
            // Boss name
            Text(boss.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CORRUPTION CLEARED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(1)
                    Spacer()
                    Text("\(Int(progress.progressPercent))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#FACC15"))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#374151").opacity(0.3))
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#EF4444"), Color(hex: "#F97316")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(progress.progressPercent / 100.0))
                    }
                }
                .frame(height: 12)
            }
            .frame(width: 280)
        }
    }
    
    // MARK: - Damage Info Section
    
    private var damageInfoSection: some View {
        VStack(spacing: 16) {
            // Damage dealt
            HStack {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#F59E0B"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DAMAGE DEALT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        Text("+\(result.damageDealt)")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(Color(hex: "#EF4444"))
                    }
                }
                Spacer()
            }
            
            // Total progress
            HStack {
                Spacer()
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#3B82F6"))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL PROGRESS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        Text("\(Int(progress.progressPercent))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "#FACC15"))
                    }
                }
                Spacer()
            }
            
            // Remaining HP
            if !isBossDefeated {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#EF4444"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("REMAINING HP")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1)
                            
                            Text("\(progress.remainingHp)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                // Dark glassmorphic background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#1a1a1a").opacity(0.85),
                                Color(hex: "#0f0f0f").opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blur(radius: 0.5)
                
                // Subtle dark overlay for glass effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.3),
                                Color.black.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Rewards Card
    
    private func rewardsCard(rewards: (xp: Int, gold: Int)) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REWARDS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                    
                    HStack(alignment: .center, spacing: 12) {
                        // XP Reward
                        Text("+\(rewards.xp) XP")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(Color(hex: "#4ADE80"))
                            .tracking(-0.5)
                        
                        // Gold Reward
                        Text("+\(rewards.gold) Gold")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#FACC15"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FACC15").opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Trophy icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#f49d25").opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#f49d25").opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#f49d25"))
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#27221B").opacity(0.9),
                    Color(hex: "#181511").opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Circle()
                .fill(Color(hex: "#f49d25").opacity(0.1))
                .frame(width: 128, height: 128)
                .blur(radius: 40)
                .offset(x: 64, y: -64),
            alignment: .topTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Floating Particles
    
    private var floatingParticles: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#f49d25"))
                .frame(width: 8, height: 8)
                .opacity(0.6)
                .position(x: UIScreen.main.bounds.width * 0.1, y: 40)
            
            Circle()
                .fill(Color(hex: "#FDE047"))
                .frame(width: 12, height: 12)
                .opacity(0.5)
                .position(x: UIScreen.main.bounds.width * 0.8, y: 80)
            
            Circle()
                .fill(Color(hex: "#f49d25").opacity(0.8))
                .frame(width: 6, height: 6)
                .opacity(0.7)
                .position(x: UIScreen.main.bounds.width * 0.3, y: 160)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isBossDefeated {
                // When boss is defeated: Only Return Home button with orange background
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onReturnHome()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Return Home")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#f49d25"), Color(hex: "#EA580C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "#B4640A"), radius: 0, x: 0, y: 4)
                }
                .buttonStyle(BattleButtonStyle())
            } else {
                // When boss is NOT defeated: Attack Again button + Return Home button
                // Attack Again button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onAttackAgain()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("ATTACK AGAIN")
                            .font(.system(size: 18, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#f49d25"), Color(hex: "#EA580C")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "#B4640A"), radius: 0, x: 0, y: 4)
                }
                .buttonStyle(BattleButtonStyle())
                
                // Return Home button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onReturnHome()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16))
                        Text("Return Home")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                }
            }
        }
    }
}

// MARK: - Battle Button Style

struct BattleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 4 : 0)
            .shadow(
                color: Color(hex: "#B4640A"),
                radius: 0,
                x: 0,
                y: configuration.isPressed ? 0 : 4
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Portal Boss Item Drop Modal (separate from daily drop modal)

struct PortalBossItemDropModalView: View {
    let item: PortalItem
    let onDismiss: () -> Void
    
    // Animation state variables (same as ItemDropModalView)
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    @State private var borderOpacity: Double = 0
    @State private var itemScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var showConfetti: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background: Semi-transparent black overlay
                Color.black.opacity(backgroundOpacity)
                    .ignoresSafeArea()
                
                // Glassmorphic card container
                VStack(spacing: 16) {
                    // Title - Updated for portal cleared item
                    Text("PORTAL CLEARED! 🎁")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 2)
                        .opacity(contentOpacity)
                    
                    // Subtitle
                    Text("Boss Defeated Reward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(contentOpacity)
                    
                    // Rank badge
                    Text("\(item.rolledRank)-RANK")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(item.rankColor)
                        .cornerRadius(10)
                        .shadow(color: item.rankColor.opacity(0.5), radius: 8, x: 0, y: 0)
                        .opacity(contentOpacity)
                    
                    // Item icon (separate for pop animation)
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
                                .shadow(color: item.rankColor.opacity(0.6), radius: 20, x: 0, y: 0)
                        case .failure:
                            Image(systemName: "gift.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.8))
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .scaleEffect(itemScale)
                    
                    // Item name
                    Text(item.name)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .opacity(contentOpacity)
                    
                    // Stat bonus
                    Text("+\(item.statValue) \(item.statType)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(item.rankColor.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(item.rankColor.opacity(0.5), lineWidth: 1)
                        )
                        .opacity(contentOpacity)
                    
                    // Collect button
                    Button(action: onDismiss) {
                        Text("Collect")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(item.rankColor)
                            .cornerRadius(25)
                            .shadow(color: item.rankColor.opacity(0.6), radius: 15, x: 0, y: 5)
                    }
                    .opacity(contentOpacity)
                }
                .padding(.top, 30)
                .padding(.bottom, 30)
                .padding(.horizontal, 30)
                .scaleEffect(cardScale)
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
                    // Rank-colored border
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(item.rankColor.opacity(borderOpacity), lineWidth: 2.5)
                )
                .shadow(color: item.rankColor.opacity(0.4 * borderOpacity), radius: 25, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.3), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 20)
                
                // Sparkle rain overlay - ON TOP of card
                if showConfetti {
                    SparkleRainView(
                        primaryColor: item.rankColor,
                        particleCount: 50
                    )
                    .allowsHitTesting(false)
                }
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
        // Same animation sequence as ItemDropModalView
        // Phase 1: Modal Fade In (0.3s)
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0.45
        }
        
        // Phase 2: Card Entrance (0.5s, starts at 0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardScale = 1.0
                borderOpacity = 1.0
            }
        }
        
        // Phase 3: Item Pop (0.4s, starts at 0.5s) + Confetti (starts at 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Item pop animation with subtle bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                itemScale = 1.1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    itemScale = 1.0
                }
            }
            
            // Start confetti slightly after item pop
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
        }
        
        // Phase 5: Content Fade (0.3s, starts at 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

