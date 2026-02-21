//
//  PortalRaidMapView.swift
//  Animarc IOS
//
//  Vertical RPG-style map showing boss progression as connected stops
//

import SwiftUI

// MARK: - Boss Node State

enum BossNodeState {
    case defeated
    case current
    case locked
}

// MARK: - Portal Raid Map View

struct PortalRaidMapView: View {
    let bosses: [PortalBoss]
    let completedIds: Set<UUID>
    let bossProgress: [UUID: PortalRaidProgress]
    let bossAttemptsRemaining: Int
    let onBossTapped: (PortalBoss) -> Void
    
    private var categorized: (defeated: [PortalBoss], current: PortalBoss?, locked: [PortalBoss]) {
        PortalService.categorizeBosses(bosses: bosses, completedIds: completedIds)
    }
    
    private var sortedBosses: [PortalBoss] {
        bosses.sorted { $0.mapOrder < $1.mapOrder }
    }
    
    var body: some View {
        ZStack {
            // Background
            ZStack {
                Color(hex: "#0B0E14")
                RadialGradient(
                    colors: [Color(hex: "#1a202c"), Color(hex: "#0B0E14")],
                    center: .center,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
            }
            .ignoresSafeArea()
            
            // Floating ambient particles
            FloatingParticlesView()
            
            // Scrollable map
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    mapContent
                        .padding(.top, 20)
                        .padding(.bottom, 180)
                }
                .onAppear {
                    if let current = categorized.current {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("boss-\(current.id)", anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: completedIds) { _, _ in
                    if let current = categorized.current {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("boss-\(current.id)", anchor: .center)
                        }
                    }
                }
            }
            
            // Gradient fade at bottom (non-interactive, below footer)
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color(hex: "#0B0E14").opacity(0.95), Color(hex: "#0B0E14")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 160)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            
            // Fixed footer with current boss card (on top of gradient)
            VStack {
                Spacer()
                if let current = categorized.current {
                    currentBossFooter(boss: current)
                }
            }
        }
    }
    
    // MARK: - Map Content
    
    private var mapContent: some View {
        let reversed = sortedBosses.reversed().map { $0 }
        
        return VStack(spacing: 0) {
            ForEach(Array(reversed.enumerated()), id: \.element.id) { index, boss in
                let state = nodeState(for: boss)
                let isLeftAligned = index % 2 == 0
                
                MapNodeRow(
                    boss: boss,
                    state: state,
                    progress: bossProgress[boss.id],
                    isLeftAligned: isLeftAligned,
                    onTap: {
                        if state != .locked {
                            onBossTapped(boss)
                        }
                    }
                )
                .id("boss-\(boss.id)")
                
                if index < reversed.count - 1 {
                    MapPathSegment(fromLeft: isLeftAligned)
                        .frame(height: 110)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Current Boss Footer
    
    private func currentBossFooter(boss: PortalBoss) -> some View {
        Button(action: { onBossTapped(boss) }) {
            HStack(spacing: 12) {
                // Boss icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(boss.rankColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    if let uiImage = UIImage(named: boss.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22))
                            .foregroundColor(boss.rankColor)
                    }
                }
                
                // Boss info
                VStack(alignment: .leading, spacing: 2) {
                    Text(boss.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Level \(boss.bossLevel) \u{2022} \(boss.rank)-Rank")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                
                Spacer()
                
                // Reward
                VStack(alignment: .trailing, spacing: 2) {
                    Text("REWARD")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .tracking(0.5)
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#FACC15"))
                        Text("\(PortalService.calculateBossRewards(bossRank: boss.rank, bossLevel: boss.bossLevel).gold)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#F59E0B"))
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    Color(hex: "#161B22").opacity(0.7)
                    VisualEffectBlur(blurStyle: .dark)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
    
    // MARK: - Helpers
    
    private func nodeState(for boss: PortalBoss) -> BossNodeState {
        if completedIds.contains(boss.id) {
            return .defeated
        } else if boss.id == categorized.current?.id {
            return .current
        } else {
            return .locked
        }
    }
}

// MARK: - Map Node Row

struct MapNodeRow: View {
    let boss: PortalBoss
    let state: BossNodeState
    let progress: PortalRaidProgress?
    let isLeftAligned: Bool
    let onTap: () -> Void
    
    @State private var glowPulse = false
    
    var body: some View {
        HStack(spacing: 0) {
            if !isLeftAligned {
                Spacer()
            }
            
            HStack(spacing: 12) {
                if isLeftAligned {
                    nodeCircle
                    labelCard
                } else {
                    labelCard
                    nodeCircle
                }
            }
            
            if isLeftAligned {
                Spacer()
            }
        }
        .padding(isLeftAligned ? .leading : .trailing, 30)
    }
    
    // MARK: - Node Circle
    
    private var nodeCircle: some View {
        Button(action: onTap) {
            ZStack {
                switch state {
                case .current:
                    // Outer glow ring
                    Circle()
                        .fill(Color(hex: "#F59E0B").opacity(0.1))
                        .frame(width: 64, height: 64)
                        .opacity(glowPulse ? 0.8 : 0.4)
                    
                    // Main node
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FBBF24"), Color(hex: "#F59E0B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color(hex: "#F59E0B").opacity(0.6), radius: 12)
                    
                    Text("⚔️")
                        .font(.system(size: 22))
                    
                case .defeated:
                    Circle()
                        .fill(Color(hex: "#22C55E").opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#22C55E").opacity(0.5), lineWidth: 2)
                        )
                    
                    Circle()
                        .fill(Color(hex: "#22C55E"))
                        .frame(width: 14, height: 14)
                    
                case .locked:
                    Circle()
                        .fill(Color(hex: "#1E293B"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#374151"), lineWidth: 3)
                        )
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4B5563"))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if state == .current {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }
    
    // MARK: - Label Card
    
    private var labelCard: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Boss thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(thumbnailBackground)
                        .frame(width: bossThumbSize, height: bossThumbSize)
                    
                    if let uiImage = UIImage(named: boss.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: bossThumbSize - 6, height: bossThumbSize - 6)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .opacity(state == .locked ? 0.3 : (state == .defeated ? 0.6 : 1.0))
                            .grayscale(state == .locked ? 1.0 : 0.0)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    statusLabel
                    Text(boss.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(state == .locked ? 0.5 : (state == .defeated ? 0.7 : 1.0))
                }
                .padding(.trailing, 8)
            }
            .padding(8)
            .background(
                ZStack {
                    Color(hex: "#161B22").opacity(0.7)
                    VisualEffectBlur(blurStyle: .dark)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(labelBorderColor, lineWidth: 1)
            )
            .shadow(color: state == .current ? Color(hex: "#F59E0B").opacity(0.15) : .clear, radius: 15)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(state == .locked)
    }
    
    private var bossThumbSize: CGFloat {
        state == .current ? 48 : 40
    }
    
    private var thumbnailBackground: Color {
        switch state {
        case .current: return Color(hex: "#F59E0B").opacity(0.2)
        case .defeated: return Color(hex: "#22C55E").opacity(0.1)
        case .locked: return Color(hex: "#1E293B")
        }
    }
    
    private var labelBorderColor: Color {
        switch state {
        case .current: return Color(hex: "#F59E0B").opacity(0.3)
        case .defeated: return Color(hex: "#22C55E").opacity(0.2)
        case .locked: return Color.white.opacity(0.05)
        }
    }
    
    @ViewBuilder
    private var statusLabel: some View {
        switch state {
        case .current:
            Text("CURRENT")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "#F59E0B"))
                .tracking(1.5)
        case .defeated:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#22C55E"))
                Text("DEFEATED")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#22C55E"))
                    .tracking(1.5)
            }
        case .locked:
            Text("LOCKED")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "#6B7280"))
                .tracking(1.5)
        }
    }
}

// MARK: - Map Path Segment (S-curve between two adjacent nodes)

struct MapPathSegment: View {
    let fromLeft: Bool
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let nodeInset: CGFloat = 52
            let startX = fromLeft ? nodeInset : w - nodeInset
            let endX = fromLeft ? w - nodeInset : nodeInset
            
            Path { path in
                path.move(to: CGPoint(x: startX, y: 0))
                path.addCurve(
                    to: CGPoint(x: endX, y: h),
                    control1: CGPoint(x: startX, y: h * 0.45),
                    control2: CGPoint(x: endX, y: h * 0.55)
                )
            }
            .stroke(
                Color.white.opacity(0.08),
                style: StrokeStyle(lineWidth: 3, dash: [8, 8])
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Floating Particles

struct FloatingParticlesView: View {
    var body: some View {
        ZStack {
            FloatingDot(size: 3, x: 0.2, y: 0.1, delay: 0)
            FloatingDot(size: 4, x: 0.8, y: 0.4, delay: 2)
            FloatingDot(size: 2, x: 0.1, y: 0.7, delay: 4)
            FloatingDot(size: 3, x: 0.6, y: 0.85, delay: 1)
            FloatingDot(size: 2, x: 0.9, y: 0.2, delay: 3)
            FloatingDot(size: 3, x: 0.35, y: 0.55, delay: 5)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct FloatingDot: View {
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    
    @State private var floating = false
    
    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .opacity(0.3)
                .position(
                    x: geo.size.width * x,
                    y: geo.size.height * y + (floating ? -15 : 15)
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(delay)) {
                        floating = true
                    }
                }
        }
    }
}

// MARK: - Visual Effect Blur

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
