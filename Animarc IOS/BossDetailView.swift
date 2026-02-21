//
//  BossDetailView.swift
//  Animarc IOS
//
//  Full-screen boss detail page showing stats, progress, and attack button
//

import SwiftUI

struct BossDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let boss: PortalBoss
    let progress: PortalRaidProgress?
    let userStats: BattlerStats
    let isCurrentBoss: Bool
    let bossAttemptsRemaining: Int
    let onAttack: () -> Void
    
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var contentAppeared = false
    
    private var rankInfo: RankInfo? {
        RankService.getRankByCode(boss.rank)
    }
    
    private var rankColor: Color {
        rankInfo?.swiftUIColor ?? Color.gray
    }
    
    private var bossRewards: (xp: Int, gold: Int) {
        PortalService.calculateBossRewards(bossRank: boss.rank, bossLevel: boss.bossLevel)
    }
    
    private var estimatedAttempts: String {
        let remainingHP = progress?.remainingHp ?? boss.maxHp
        let estimate = PortalService.estimateAttemptsNeeded(
            userStats: userStats,
            bossStats: boss.battlerStats,
            remainingHP: remainingHP
        )
        if estimate.min == estimate.max {
            if estimate.min == 1 { return "Short" }
            else if estimate.min <= 3 { return "~\(estimate.min)-\(estimate.max) Attempts" }
            else { return "Long" }
        }
        return "~\(estimate.min)-\(estimate.max) Attempts"
    }
    
    private var estimatedEffortIcon: String {
        let remainingHP = progress?.remainingHp ?? boss.maxHp
        let estimate = PortalService.estimateAttemptsNeeded(
            userStats: userStats,
            bossStats: boss.battlerStats,
            remainingHP: remainingHP
        )
        if estimate.min <= 1 { return "hourglass" }
        else if estimate.min <= 3 { return "clock" }
        else { return "hourglass.bottom" }
    }
    
    private var specializationIcon: String {
        switch boss.specialization {
        case "Tank": return "shield.fill"
        case "Glass Cannon": return "sparkles"
        case "Speedster": return "bolt.fill"
        case "Balanced": return "equal.circle.fill"
        default: return "equal.circle.fill"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0B0E14")
                .ignoresSafeArea()
            
            // Gradient glow from top
            VStack {
                RadialGradient(
                    colors: [rankColor.opacity(0.15), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .frame(height: 400)
                Spacer()
            }
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with back button and XP
                    headerBar
                        .padding(.top, 8)
                    
                    // Badges row
                    badgesRow
                        .padding(.top, 16)
                    
                    // Boss avatar with animated rings
                    bossAvatar
                        .padding(.top, 24)
                    
                    // Boss name
                    Text(boss.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .white.opacity(0.2), radius: 5)
                        .padding(.top, 16)
                    
                    // Progress bar
                    progressSection
                        .padding(.top, 20)
                        .padding(.horizontal, 24)
                    
                    // Stats row
                    statsRow
                        .padding(.top, 24)
                        .padding(.horizontal, 20)
                    
                    // Effort + Rewards
                    effortRewardsRow
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    // Attack button (only for current boss)
                    if isCurrentBoss {
                        attackButton
                            .padding(.top, 28)
                            .padding(.horizontal, 20)
                    } else {
                        defeatedBadge
                            .padding(.top, 28)
                    }
                    
                    // Back to map
                    Button(action: { dismiss() }) {
                        Text("BACK TO MAP")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .tracking(1.5)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .opacity(contentAppeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                contentAppeared = true
            }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                outerRotation = 360
            }
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                innerRotation = -360
            }
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#374151").opacity(0.3))
                    .cornerRadius(20)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Badges
    
    private var badgesRow: some View {
        HStack {
            // Specialization badge
            HStack(spacing: 6) {
                Image(systemName: specializationIcon)
                    .font(.system(size: 12))
                Text(boss.specialization.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(boss.specializationColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(boss.specializationColor.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(boss.specializationColor.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            // Rank badge
            Text("\(boss.rank)-RANK")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(rankColor)
                .tracking(1.5)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(rankColor.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(rankColor.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Boss Avatar
    
    private var bossAvatar: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(rankColor.opacity(0.3), lineWidth: 1)
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(outerRotation))
            
            // Dashed ring
            Circle()
                .stroke(rankColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(innerRotation))
            
            // Gradient background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [rankColor.opacity(0.3), Color(hex: "#1e293b").opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 4)
            
            // Avatar image
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
                                .font(.system(size: 50))
                        )
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [rankColor.opacity(0.8), rankColor.opacity(0.4), Color(hex: "#1e293b")],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: rankColor.opacity(0.5), radius: 12)
            
            // Defeated overlay
            if !isCurrentBoss {
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 112, height: 112)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "#22C55E"))
            }
            
            // Level badge
            VStack {
                Spacer()
                Text("LV. \(boss.bossLevel)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [rankColor.opacity(0.9), rankColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(rankColor.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: rankColor.opacity(0.5), radius: 5)
                    .offset(y: 10)
            }
            .frame(width: 112, height: 112)
        }
        .frame(height: 160)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("CLEARED")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(2)
                Spacer()
                Text("\(Int(progress?.progressPercent ?? 0))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(rankColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: "#1e293b").opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [rankColor.opacity(0.9), rankColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat((progress?.progressPercent ?? 0) / 100.0))
                        .shadow(color: rankColor.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 10)
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: 0) {
            StatItem(icon: "⚔️", label: "ATK", value: "\(boss.statAttack)", color: Color(hex: "#FACC15"))
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.1))
            
            StatItem(icon: "🛡️", label: "DEF", value: "\(boss.statDefense)", color: Color(hex: "#3B82F6"))
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.1))
            
            StatItem(icon: "❤️", label: "HP", value: "\(boss.maxHp)", color: Color(hex: "#EF4444"))
            
            Divider()
                .frame(height: 40)
                .background(Color.white.opacity(0.1))
            
            StatItem(icon: "⚡", label: "SPD", value: "\(boss.statSpeed)", color: Color(hex: "#10B981"))
        }
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.2))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // MARK: - Effort + Rewards
    
    private var effortRewardsRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("EST. EFFORT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(1.5)
                HStack(spacing: 6) {
                    Image(systemName: estimatedEffortIcon)
                        .font(.system(size: 14))
                        .foregroundColor(rankColor.opacity(0.8))
                    Text(estimatedAttempts)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 36)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("BOSS REWARDS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(1.5)
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#60A5FA"))
                        Text("\(bossRewards.xp) XP")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#FACC15"))
                        Text("\(bossRewards.gold)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: "#FEF3C7"))
                    }
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 12))
                        .foregroundColor(rankColor)
                        .shadow(color: rankColor.opacity(0.5), radius: 3)
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Attack Button
    
    private var attackButton: some View {
        Button(action: onAttack) {
            HStack(spacing: 10) {
                Text("⚔️")
                    .font(.system(size: 20))
                Text("ATTACK BOSS")
                    .font(.system(size: 20, weight: .bold))
                    .tracking(2)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#FFE766"),
                        Color(hex: "#E87B41")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: Color(hex: "#FFE766").opacity(0.4), radius: 15, x: 0, y: 0)
            .shadow(color: Color(hex: "#E87B41").opacity(0.3), radius: 25, x: 0, y: 0)
        }
        .opacity(bossAttemptsRemaining > 0 ? 1.0 : 0.6)
    }
    
    // MARK: - Defeated Badge
    
    private var defeatedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#22C55E"))
            Text("DEFEATED")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#22C55E"))
                .tracking(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(hex: "#22C55E").opacity(0.1))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "#22C55E").opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
