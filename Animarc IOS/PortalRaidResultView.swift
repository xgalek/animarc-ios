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
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: showRewards)
                
                // Rewards card (only if defeated)
                if isBossDefeated, let rewards = rewards {
                    rewardsCard(rewards: rewards)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRewards = true
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
                .font(.system(size: 56, weight: .black))
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
            
            // Total progress
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
            
            // Remaining HP
            if !isBossDefeated {
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
            }
        }
        .padding(20)
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
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
            // Attack Again button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onAttackAgain()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text(isBossDefeated ? "NEXT BOSS" : "ATTACK AGAIN")
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

