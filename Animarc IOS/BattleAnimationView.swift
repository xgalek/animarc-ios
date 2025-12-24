//
//  BattleAnimationView.swift
//  Animarc IOS
//
//  Battle resolution animation screen
//  Shows a brief, suspenseful animation before revealing battle results
//

import SwiftUI

// MARK: - Battle Animation Phase

enum BattleAnimationPhase {
    case intro          // Avatars appear
    case battling       // Energy animation in progress
    case suspense       // Pause at 90% - builds anticipation
    case revealing      // Result revealed
    case complete       // Transition to result screen
}

// MARK: - Battle Animation View

struct BattleAnimationView: View {
    let userAvatar: String      // "ProfileIcon/profile image"
    let opponentAvatar: String  // Opponent image name
    let userStats: BattlerStats
    let opponentStats: BattlerStats
    let onComplete: (BattleResult) -> Void
    
    // Animation state
    @State private var phase: BattleAnimationPhase = .intro
    @State private var backgroundOpacity: Double = 1.0  // Start fully visible to prevent white flash
    @State private var avatarScale: CGFloat = 0.7
    @State private var avatarOpacity: Double = 0
    @State private var energyProgress: CGFloat = 0
    @State private var statusTextOpacity: Double = 0
    @State private var showParticles = false
    @State private var showCompletionBurst = false
    @State private var suspenseGlowOpacity: Double = 0
    @State private var resultCalculated: BattleResult?
    
    // Colors matching app theme
    private let goldColor = Color(hex: "#F59E0B")
    private let orangeColor = Color(hex: "#FF9500")
    private let yellowColor = Color(hex: "#FACC15")
    
    var body: some View {
        ZStack {
            // Background - dark theme matching BattleResultView (always visible)
            Color(hex: "#191919")
                .ignoresSafeArea()
            
            // Subtle radial glow from center
            RadialGradient(
                colors: [goldColor.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height * 0.5
            )
            .ignoresSafeArea()
            
            // Particle system (background layer)
            if showParticles {
                BattleParticleView()
                    .allowsHitTesting(false)
            }
            
            // Main content - all in fixed positions
            VStack(spacing: 24) {
                Spacer()
                
                // Character portraits row - fixed height
                HStack(alignment: .center, spacing: 0) {
                    // User avatar (left)
                    avatarView(
                        imageName: userAvatar,
                        isUser: true
                    )
                    
                    Spacer()
                    
                    // Opponent avatar (right)
                    avatarView(
                        imageName: opponentAvatar,
                        isUser: false
                    )
                }
                .frame(height: 120) // Fixed height
                .padding(.horizontal, 40)
                
                // Energy bar - fixed height, directly under avatars
                energyAnimationView
                    .frame(height: 20) // Fixed height with padding
                    .padding(.horizontal, 60)
                
                // Status text - FIXED HEIGHT container to prevent layout shifts
                statusTextView
                    .frame(height: 60) // Fixed height - dots won't cause shift
                    .opacity(statusTextOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            startBattleSequence()
        }
    }
    
    // MARK: - Avatar View
    
    private func avatarView(imageName: String, isUser: Bool) -> some View {
        // Fixed size container to prevent any layout shifts
        ZStack {
            // Glow effect - always present, opacity animated (prevents layout shift)
            Circle()
                .fill(goldColor.opacity(0.4))
                .frame(width: 120, height: 120)
                .blur(radius: 20)
                .opacity(suspenseGlowOpacity)
            
            // Avatar image - fixed frame, no conditional elements
            Group {
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Circle()
                        .fill(Color(hex: "#374151"))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 32))
                        )
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [goldColor, orangeColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
            )
            .shadow(color: goldColor.opacity(0.4), radius: 10)
        }
        .frame(width: 120, height: 120) // Fixed container size
        .scaleEffect(avatarScale)
        .opacity(avatarOpacity)
    }
    
    // MARK: - Energy Animation View
    
    private var energyAnimationView: some View {
        ZStack {
            // Energy bar - fixed height, no conditional elements inside
            GeometryReader { geometry in
                ZStack {
                    // Background track
                    Capsule()
                        .fill(Color(hex: "#374151").opacity(0.3))
                        .frame(height: 8)
                    
                    // Animated energy fill
                    HStack(spacing: 0) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [goldColor, orangeColor, yellowColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geometry.size.width * energyProgress), height: 8)
                            .shadow(color: orangeColor.opacity(0.6), radius: 8, x: 0, y: 0)
                        
                        Spacer(minLength: 0)
                    }
                    
                    // Glowing orb - always present, opacity controlled
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white, yellowColor, orangeColor],
                                center: .center,
                                startRadius: 0,
                                endRadius: 8
                            )
                        )
                        .frame(width: 16, height: 16)
                        .shadow(color: yellowColor.opacity(0.8), radius: 12, x: 0, y: 0)
                        .offset(x: -geometry.size.width / 2 + (geometry.size.width * energyProgress))
                        .opacity(energyProgress > 0 ? 1 : 0)
                }
                .frame(height: 8)
            }
            .frame(height: 8)
            
            // Completion burst effect - outside GeometryReader, won't affect bar layout
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.6), yellowColor.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 8)
                .opacity(showCompletionBurst ? 1 : 0)
                .allowsHitTesting(false)
        }
    }
    
    // MARK: - Status Text View
    
    private var statusTextView: some View {
        // Fixed size container - nothing inside should cause layout shifts
        VStack(spacing: 8) {
            // Main status text
            Text(statusText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Dots - ALWAYS present, opacity controlled (no layout shift)
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(goldColor)
                        .frame(width: 6, height: 6)
                        .opacity(dotsVisible ? loadingDotOpacity(index: index) : 0)
                }
            }
        }
    }
    
    private var dotsVisible: Bool {
        phase == .battling || phase == .suspense
    }
    
    private var statusText: String {
        switch phase {
        case .intro, .battling:
            return "Attacking boss..."
        case .suspense:
            return "Calculating damage..."
        case .revealing, .complete:
            return ""
        }
    }
    
    private func loadingDotOpacity(index: Int) -> Double {
        let baseDelay = Double(index) * 0.2
        return 0.3 + 0.7 * abs(sin(Date().timeIntervalSinceReferenceDate * 2 + baseDelay))
    }
    
    // MARK: - Animation Sequence
    
    private func startBattleSequence() {
        // Calculate battle result early (but don't show it yet)
        calculateBattleResult()
        
        // ═══════════════════════════════════════════════════════════
        // Phase 1: INTRO (0.0s - 0.8s)
        // ═══════════════════════════════════════════════════════════
        
        // Avatars scale in smoothly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                avatarScale = 1.0
                avatarOpacity = 1.0
            }
        }
        
        // Status text fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                statusTextOpacity = 1.0
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // Phase 2: BATTLING (0.8s - 3.3s) - slow energy fill to 90%
        // ═══════════════════════════════════════════════════════════
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            phase = .battling
            showParticles = true
            
            // Haptic feedback at battle start
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Energy bar fills to 90% over 2.5 seconds - nice and slow
            withAnimation(.easeInOut(duration: 2.5)) {
                energyProgress = 0.9
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // Phase 3: SUSPENSE (3.3s - 4.5s) - THE ANTICIPATION MOMENT ⭐
        // ═══════════════════════════════════════════════════════════
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            phase = .suspense
            
            // Haptic pulse for suspense
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Fade in avatar glow smoothly
            withAnimation(.easeIn(duration: 0.4)) {
                suspenseGlowOpacity = 1.0
            }
            
            // Brief text fade for transition effect
            withAnimation(.easeOut(duration: 0.2)) {
                statusTextOpacity = 0.3
            }
        }
        
        // Text comes back stronger during suspense
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                statusTextOpacity = 1.0
            }
        }
        
        // Second suspense haptic for more tension
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        // ═══════════════════════════════════════════════════════════
        // Phase 4: REVEALING (4.5s - 5.0s) - THE REVEAL
        // ═══════════════════════════════════════════════════════════
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            phase = .revealing
            
            // Complete energy bar
            withAnimation(.easeOut(duration: 0.3)) {
                energyProgress = 1.0
            }
            
            // Show completion burst
            withAnimation(.easeOut(duration: 0.2)) {
                showCompletionBurst = true
            }
            
            // Fade out avatar glow
            withAnimation(.easeOut(duration: 0.3)) {
                suspenseGlowOpacity = 0
            }
            
            // Strong result haptic
            if let result = resultCalculated {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(result.didWin ? .success : .warning)
            }
            
            // Fade out status text
            withAnimation(.easeOut(duration: 0.3)) {
                statusTextOpacity = 0.5
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // Phase 5: HOLD (5.0s - 5.5s) - Let user see the result
        // ═══════════════════════════════════════════════════════════
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            // Hold the complete state, fade out burst
            withAnimation(.easeOut(duration: 0.3)) {
                showCompletionBurst = false
                statusTextOpacity = 0
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // Phase 6: TRANSITION (5.5s) - Go to result screen
        // ═══════════════════════════════════════════════════════════
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            phase = .complete
            
            // Trigger completion callback
            if let result = resultCalculated {
                onComplete(result)
            }
        }
    }
    
    private func calculateBattleResult() {
        // Use stat-based BattleService to calculate result
        let (didWin, difficulty, performance) = BattleService.simulateBattle(
            userStats: userStats,
            opponentStats: opponentStats
        )
        
        let (xp, gold) = BattleService.calculateRewards(
            didWin: didWin,
            difficulty: difficulty,
            performance: performance,
            exactGold: nil // Will be set by caller
        )
        
        resultCalculated = BattleResult(
            didWin: didWin,
            xpEarned: xp,
            goldEarned: gold,
            opponentName: "",
            difficultyTier: difficulty,
            performance: performance
        )
    }
}

// MARK: - Battle Particle System

struct BattleParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double
    var rotationSpeed: Double
    var opacity: Double = 1.0
    var size: CGFloat
    var color: Color
}

struct BattleParticleView: View {
    @State private var particles: [BattleParticle] = []
    @State private var timer: Timer?
    @State private var spawnTimer: Timer?
    @State private var startTime: Date = Date()
    
    private let particleColors = [
        Color(hex: "#F59E0B"),  // Gold
        Color(hex: "#FF9500"),  // Orange
        Color(hex: "#FACC15"),  // Yellow
        Color(hex: "#FDE047"),  // Light yellow
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    // Sparkle shape
                    Image(systemName: "sparkle")
                        .font(.system(size: particle.size))
                        .foregroundColor(particle.color)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .shadow(color: particle.color.opacity(0.6), radius: 4, x: 0, y: 0)
                }
            }
            .onAppear {
                startTime = Date()
                startSpawnTimer(in: geometry.size)
                startUpdateTimer(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
                spawnTimer?.invalidate()
            }
        }
    }
    
    private func startSpawnTimer(in size: CGSize) {
        // Spawn new particles every 0.15 seconds
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            spawnParticle(in: size)
        }
    }
    
    private func spawnParticle(in size: CGSize) {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Stop spawning after 4.0 seconds - matches new longer animation
        if elapsed > 4.0 {
            spawnTimer?.invalidate()
            return
        }
        
        // Random particle size
        let particleSize = CGFloat.random(in: 8...16)
        
        // Random color from palette
        let color = particleColors.randomElement() ?? particleColors[0]
        
        // Spawn from center area, moving outward gently
        let centerX = size.width / 2
        let centerY = size.height / 2
        let spawnRadius = CGFloat.random(in: 20...60)
        let angle = Double.random(in: 0...(2 * Double.pi))
        
        let startX = centerX + cos(angle) * spawnRadius
        let startY = centerY + sin(angle) * spawnRadius
        
        // Gentle outward velocity
        let speed = Double.random(in: 15...35)
        let velocityX = cos(angle) * speed
        let velocityY = sin(angle) * speed
        
        let particle = BattleParticle(
            position: CGPoint(x: startX, y: startY),
            velocity: CGVector(dx: velocityX, dy: velocityY),
            rotation: Double.random(in: 0...360),
            rotationSpeed: Double.random(in: -60...60),
            size: particleSize,
            color: color
        )
        
        particles.append(particle)
    }
    
    private func startUpdateTimer(in size: CGSize) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles(in: size)
        }
    }
    
    private func updateParticles(in size: CGSize) {
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Stop updating after 5.2 seconds - matches new animation duration
        if elapsed > 5.2 {
            timer?.invalidate()
            return
        }
        
        for i in particles.indices {
            // Update position
            particles[i].position.x += particles[i].velocity.dx * 0.016
            particles[i].position.y += particles[i].velocity.dy * 0.016
            
            // Slow down over time (air resistance)
            particles[i].velocity.dx *= 0.98
            particles[i].velocity.dy *= 0.98
            
            // Update rotation
            particles[i].rotation += particles[i].rotationSpeed * 0.016
            
            // Fade out gradually - starts later to keep particles visible longer
            if elapsed > 3.5 {
                let fadeProgress = min((elapsed - 3.5) / 1.5, 1.0)
                particles[i].opacity = 1.0 - fadeProgress
            }
        }
        
        // Remove off-screen or faded particles
        particles = particles.filter { particle in
            particle.position.x > -50 &&
            particle.position.x < size.width + 50 &&
            particle.position.y > -50 &&
            particle.position.y < size.height + 50 &&
            particle.opacity > 0.01
        }
    }
}

// MARK: - Preview

#Preview {
    BattleAnimationView(
        userAvatar: "ProfileIcon/profile image",
        opponentAvatar: "Opponents/_Stylized Cute Warrior Character (2)",
        userStats: BattlerStats(
            health: 175,
            attack: 20,
            defense: 20,
            speed: 20,
            level: 5,
            focusPower: 1500
        ),
        opponentStats: BattlerStats(
            health: 165,
            attack: 25,
            defense: 15,
            speed: 25,
            level: 5,
            focusPower: 1400
        ),
        onComplete: { result in
            print("Battle complete: \(result.didWin ? "Victory" : "Defeat")")
        }
    )
}

