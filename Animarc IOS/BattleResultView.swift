//
//  BattleResultView.swift
//  Animarc IOS
//
//  Created by Aleksandar Krstevski on 11/29/25.
//

import SwiftUI

// MARK: - Battle Result View

struct BattleResultView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var progressManager: UserProgressManager
    
    let battleResult: BattleResult
    let opponent: Opponent
    let onBattleAgain: () -> Void
    let onReturnHome: () -> Void
    
    @State private var contentAppeared = false
    @State private var showRewards = false
    
    private var playerName: String {
        progressManager.userProgress?.displayName ?? "Hero"
    }
    
    private var isVictory: Bool {
        battleResult.didWin
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#221a10")
                .ignoresSafeArea()
            
            // Victory/Defeat glow gradient
            VStack {
                RadialGradient(
                    colors: isVictory
                        ? [Color(hex: "#f49d25").opacity(0.4), Color.clear]
                        : [Color(hex: "#DC2626").opacity(0.3), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
                .frame(height: UIScreen.main.bounds.height * 0.6)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            // Floating particles (only for victory)
            if isVictory {
                floatingParticles
            }
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Header - VICTORY or DEFEAT
                headerSection
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : -30)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: contentAppeared)
                
                Spacer()
                
                // Character portraits
                characterPortraitsSection
                    .opacity(contentAppeared ? 1 : 0)
                    .scaleEffect(contentAppeared ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: contentAppeared)
                
                Spacer()
                
                // Rewards card
                rewardsCard
                    .opacity(showRewards ? 1 : 0)
                    .offset(y: showRewards ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6), value: showRewards)
                
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
            // Trigger entrance animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                contentAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showRewards = true
            }
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(isVictory ? .success : .error)
        }
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
            
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "#F59E0B"))
                .frame(width: 8, height: 8)
                .rotationEffect(.degrees(45))
                .opacity(0.6)
                .position(x: UIScreen.main.bounds.width * 0.9, y: 64)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(isVictory ? "VICTORY!" : "DEFEAT")
                .font(.system(size: 56, weight: .black))
                .tracking(-1)
                .foregroundStyle(
                    isVictory
                        ? LinearGradient(
                            colors: [Color(hex: "#FDE047"), Color(hex: "#f49d25"), Color(hex: "#EA580C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color(hex: "#FCA5A5"), Color(hex: "#DC2626"), Color(hex: "#991B1B")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 4)
            
            // Glowing underline
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    isVictory
                        ? Color(hex: "#f49d25").opacity(0.5)
                        : Color(hex: "#DC2626").opacity(0.5)
                )
                .frame(width: 96, height: 4)
                .blur(radius: 2)
        }
    }
    
    // MARK: - Character Portraits Section
    
    private var characterPortraitsSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Player (winner if victory)
            characterPortrait(
                name: playerName,
                avatarUrl: nil, // TODO: Add player avatar URL when available
                isWinner: isVictory
            )
            
            Spacer()
            
            // VS Swords Icon
            vsIcon
            
            Spacer()
            
            // Opponent (winner if defeat)
            characterPortrait(
                name: opponent.name,
                avatarUrl: opponent.avatarUrl,
                isWinner: !isVictory
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func characterPortrait(name: String, avatarUrl: String?, isWinner: Bool) -> some View {
        VStack(spacing: 12) {
            ZStack {
                // Glow effect for winner
                if isWinner {
                    Circle()
                        .fill(Color(hex: "#f49d25").opacity(0.4))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                }
                
                // Avatar
                ZStack {
                    if let url = avatarUrl, let imageUrl = URL(string: url) {
                        AsyncImage(url: imageUrl) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color(hex: "#374151"))
                                    .overlay(ProgressView().tint(.white))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Circle()
                                    .fill(Color(hex: "#374151"))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white.opacity(0.5))
                                            .font(.system(size: 40))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
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
                .frame(width: isWinner ? 112 : 96, height: isWinner ? 112 : 96)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isWinner ? Color(hex: "#f49d25") : Color.white.opacity(0.2),
                            lineWidth: isWinner ? 3 : 2
                        )
                )
                .shadow(
                    color: isWinner ? Color(hex: "#f49d25").opacity(0.4) : .clear,
                    radius: isWinner ? 15 : 0
                )
                .grayscale(isWinner ? 0 : 0.3)
                .opacity(isWinner ? 1 : 0.8)
                
                // Defeat X overlay
                if !isWinner {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 96, height: 96)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color(hex: "#EF4444").opacity(0.8))
                }
            }
            
            // Name
            Text(name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(isWinner ? .white : .white.opacity(0.7))
        }
        .frame(width: UIScreen.main.bounds.width * 0.35)
    }
    
    private var vsIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#221a10"))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            Image(systemName: "bolt.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.4))
                .rotationEffect(.degrees(45))
        }
        .shadow(color: .black.opacity(0.3), radius: 8)
    }
    
    // MARK: - Rewards Card
    
    private var rewardsCard: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("REWARDS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                    
                    HStack(alignment: .center, spacing: 12) {
                        // XP Reward
                        Text("+\(battleResult.xpEarned) XP")
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(Color(hex: "#4ADE80"))
                            .tracking(-0.5)
                        
                        // Gold Reward
                        if battleResult.goldEarned > 0 {
                            Text("+\(battleResult.goldEarned) Gold")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#FACC15"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "#FACC15").opacity(0.1))
                                .cornerRadius(4)
                        }
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
            // Subtle top-right glow
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
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Battle Again button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onBattleAgain()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                    Text("BATTLE AGAIN")
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.clear, lineWidth: 0)
                )
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

// MARK: - Preview

#Preview {
    BattleResultView(
        battleResult: BattleResult(
            didWin: true,
            xpEarned: 50,
            goldEarned: 100,
            opponentName: "Orc Warlord",
            difficultyTier: .fair
        ),
        opponent: Opponent(
            id: "1",
            name: "Orc Warlord",
            level: 5,
            rank: "C",
            rankColor: Color(hex: "#8B5CF6"),
            successRate: 65,
            focusPower: 1500,
            exactGoldReward: 500,
            avatarUrl: "https://example.com/avatar.jpg"
        ),
        onBattleAgain: {},
        onReturnHome: {}
    )
    .environmentObject(UserProgressManager.shared)
}

